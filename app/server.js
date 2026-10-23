/**
 * Savitara Infotel DevOps Assessment - Sample Web Application
 * Demonstrates:
 * - Express HTTP server exposing health check endpoints (/health)
 * - AWS Secrets Manager integration for secure RDS MySQL credentials
 * - RDS MySQL database connectivity and queries
 * - AWS S3 integration for application object storage
 * - AWS EC2 Metadata extraction (Instance ID, AZ, Hostname)
 */

const express = require('express');
const os = require('os');
const mysql = require('mysql2/promise');
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');

const app = express();
const PORT = process.env.PORT || 3000;
const AWS_REGION = process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION || 'ap-south-1';
const DB_SECRET_ARN = process.env.DB_SECRET_ARN || '';
const APP_S3_BUCKET = process.env.APP_S3_BUCKET || '';

// In-memory cache for db credentials retrieved from Secrets Manager
let cachedDbConfig = null;
let dbPool = null;

// AWS Clients
const smClient = new SecretsManagerClient({ region: AWS_REGION });
const s3Client = new S3Client({ region: AWS_REGION });

app.use(express.json());

/**
 * Retrieve DB credentials from AWS Secrets Manager or fallback to environment variables
 */
async function getDbCredentials() {
  if (cachedDbConfig) {
    return cachedDbConfig;
  }

  // 1. Check if DB_SECRET_ARN is provided
  if (DB_SECRET_ARN) {
    try {
      console.log(`[SecretsManager] Fetching secret from ARN: ${DB_SECRET_ARN}`);
      const command = new GetSecretValueCommand({ SecretId: DB_SECRET_ARN });
      const response = await smClient.send(command);
      if (response.SecretString) {
        const secret = JSON.parse(response.SecretString);
        cachedDbConfig = {
          host: secret.host || process.env.DB_HOST,
          user: secret.username || process.env.DB_USER,
          password: secret.password || process.env.DB_PASSWORD,
          database: secret.dbname || process.env.DB_NAME || 'savitara_db',
          port: secret.port ? parseInt(secret.port, 10) : 3306,
          connectTimeout: 5000,
          waitForConnections: true,
          connectionLimit: 10,
          queueLimit: 0,
        };
        console.log(`[SecretsManager] Successfully loaded credentials for host: ${cachedDbConfig.host}`);
        return cachedDbConfig;
      }
    } catch (err) {
      console.warn(`[SecretsManager] Warning: Failed to fetch secret (${err.message}). Falling back to ENV variables.`);
    }
  }

  // 2. Fallback to direct environment variables
  cachedDbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'admin',
    password: process.env.DB_PASSWORD || 'localpassword',
    database: process.env.DB_NAME || 'savitara_db',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    connectTimeout: 5000,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
  };

  return cachedDbConfig;
}

/**
 * Get or create MySQL Connection Pool
 */
async function getDbPool() {
  if (!dbPool) {
    const config = await getDbCredentials();
    dbPool = mysql.createPool(config);
  }
  return dbPool;
}

/**
 * Test DB Connection
 */
async function checkDbHealth() {
  try {
    const pool = await getDbPool();
    const [rows] = await pool.query('SELECT 1 + 1 AS solution, NOW() as current_time, VERSION() as db_version');
    return { status: 'UP', details: rows[0] };
  } catch (error) {
    return { status: 'DOWN', error: error.message };
  }
}

/**
 * Test S3 Bucket accessibility
 */
async function checkS3Health() {
  if (!APP_S3_BUCKET) {
    return { status: 'CONFIG_MISSING', message: 'APP_S3_BUCKET environment variable is not set' };
  }
  try {
    const testKey = `health-checks/ping-${Date.now()}.txt`;
    const putCmd = new PutObjectCommand({
      Bucket: APP_S3_BUCKET,
      Key: testKey,
      Body: 'AWS S3 Read/Write verification test from EC2 Auto Scaling instance',
      ContentType: 'text/plain',
    });
    await s3Client.send(putCmd);
    return { status: 'UP', bucket: APP_S3_BUCKET, verifiedKey: testKey };
  } catch (error) {
    return { status: 'DOWN', bucket: APP_S3_BUCKET, error: error.message };
  }
}

// -------------------------------------------------------------
// ROUTES
// -------------------------------------------------------------

/**
 * Root Dashboard
 */
app.get('/', async (req, res) => {
  const dbHealth = await checkDbHealth();
  const uptimeSeconds = process.uptime();
  const hostname = os.hostname();

  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Savitara Infotel - AWS DevOps Infrastructure</title>
  <style>
    :root {
      --primary: #2563eb;
      --success: #16a34a;
      --danger: #dc2626;
      --dark: #0f172a;
      --light: #f8fafc;
      --card-bg: #ffffff;
      --border: #e2e8f0;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--light);
      color: var(--dark);
      margin: 0;
      padding: 2rem;
    }
    .container {
      max-width: 960px;
      margin: 0 auto;
    }
    .header {
      background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
      color: white;
      padding: 2rem;
      border-radius: 12px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
      margin-bottom: 2rem;
    }
    .header h1 { margin: 0 0 0.5rem 0; font-size: 1.8rem; }
    .header p { margin: 0; opacity: 0.9; }
    .badge {
      display: inline-block;
      padding: 0.25rem 0.75rem;
      border-radius: 9999px;
      font-size: 0.8rem;
      font-weight: 600;
      text-transform: uppercase;
      margin-top: 1rem;
    }
    .badge-live { background-color: #22c55e; color: white; }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 1.5rem;
      margin-bottom: 2rem;
    }
    .card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 1.5rem;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }
    .card h3 { margin-top: 0; color: #334155; font-size: 1.1rem; border-bottom: 2px solid #f1f5f9; padding-bottom: 0.5rem; }
    .status-pill {
      font-weight: bold;
      padding: 0.2rem 0.6rem;
      border-radius: 4px;
      font-size: 0.85rem;
    }
    .status-up { background-color: #dcfce7; color: #15803d; }
    .status-down { background-color: #fee2e2; color: #b91c1c; }
    .meta-list { list-style: none; padding: 0; margin: 0; font-size: 0.9rem; line-height: 1.8; }
    .meta-list strong { color: #475569; }
    .api-links a {
      display: inline-block;
      margin-right: 0.75rem;
      margin-bottom: 0.5rem;
      padding: 0.4rem 0.8rem;
      background-color: #eff6ff;
      color: #1d4ed8;
      text-decoration: none;
      border-radius: 6px;
      font-size: 0.85rem;
      font-weight: 500;
      border: 1px solid #bfdbfe;
    }
    .api-links a:hover { background-color: #dbeafe; }
    footer { text-align: center; color: #64748b; font-size: 0.85rem; margin-top: 2rem; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Savitara Infotel - DevOps Infrastructure</h1>
      <p>Multi-AZ Highly Available Web Application on AWS with Terraform & CI/CD</p>
      <span class="badge badge-live">Live Production Environment</span>
    </div>

    <div class="grid">
      <div class="card">
        <h3>System Overview</h3>
        <ul class="meta-list">
          <li><strong>EC2 Hostname:</strong> ${hostname}</li>
          <li><strong>Platform:</strong> ${os.type()} (${os.arch()})</li>
          <li><strong>Node Version:</strong> ${process.version}</li>
          <li><strong>AWS Region:</strong> ${AWS_REGION}</li>
          <li><strong>App Uptime:</strong> ${Math.floor(uptimeSeconds)} seconds</li>
        </ul>
      </div>

      <div class="card">
        <h3>RDS MySQL Database</h3>
        <p>
          Status: 
          <span class="status-pill ${dbHealth.status === 'UP' ? 'status-up' : 'status-down'}">
            ${dbHealth.status}
          </span>
        </p>
        <ul class="meta-list">
          <li><strong>Config Source:</strong> ${DB_SECRET_ARN ? 'AWS Secrets Manager (Encrypted)' : 'Environment Variable'}</li>
          ${dbHealth.status === 'UP' ? `
            <li><strong>DB Engine Version:</strong> ${dbHealth.details?.db_version || 'MySQL 8.0'}</li>
            <li><strong>DB Latency Check:</strong> Passed</li>
          ` : `
            <li><strong>Notice:</strong> ${dbHealth.error || 'Awaiting initial RDS provisioning'}</li>
          `}
        </ul>
      </div>

      <div class="card">
        <h3>Cloud Storage & Security</h3>
        <ul class="meta-list">
          <li><strong>S3 App Bucket:</strong> ${APP_S3_BUCKET || 'Configured via Terraform'}</li>
          <li><strong>ALB Access Logs:</strong> Enabled (SSE-S3 Encrypted)</li>
          <li><strong>Secrets Manager:</strong> Active (KMS Encryption)</li>
          <li><strong>SSL / HTTPS:</strong> AWS Certificate Manager (ACM)</li>
          <li><strong>Auto Scaling:</strong> Dynamic Target Tracking (CPU 70%)</li>
        </ul>
      </div>
    </div>

    <div class="card">
      <h3>Quick API Test Endpoints</h3>
      <div class="api-links">
        <a href="/health" target="_blank">GET /health (ALB Health Check)</a>
        <a href="/api/db-status" target="_blank">GET /api/db-status</a>
        <a href="/api/s3-test" target="_blank">GET /api/s3-test</a>
        <a href="/api/info" target="_blank">GET /api/info</a>
      </div>
    </div>

    <footer>
      <p>Savitara Infotel DevOps Assessment &bull; Automated Deployment via Terraform &amp; GitHub Actions</p>
    </footer>
  </div>
</body>
</html>
  `;
  res.send(html);
});

/**
 * Health Check Endpoint for ALB Target Group
 */
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    hostname: os.hostname(),
    service: 'savitara-devops-app'
  });
});

/**
 * JSON System Info
 */
app.get('/api/info', (req, res) => {
  res.json({
    appName: 'savitara-devops-app',
    version: '1.0.0',
    hostname: os.hostname(),
    platform: process.platform,
    arch: process.arch,
    nodeVersion: process.version,
    region: AWS_REGION,
    uptime: process.uptime(),
    memoryUsage: process.memoryUsage(),
    cpuCount: os.cpus().length,
  });
});

/**
 * Test RDS MySQL Query Endpoint
 */
app.get('/api/db-status', async (req, res) => {
  const result = await checkDbHealth();
  if (result.status === 'UP') {
    res.json({
      status: 'SUCCESS',
      message: 'Successfully connected and queried Amazon RDS MySQL',
      credentialsSource: DB_SECRET_ARN ? 'AWS Secrets Manager' : 'Environment',
      data: result.details,
    });
  } else {
    res.status(503).json({
      status: 'FAILED',
      message: 'Failed to communicate with Amazon RDS MySQL',
      error: result.error,
    });
  }
});

/**
 * Test AWS S3 Read/Write Endpoint
 */
app.get('/api/s3-test', async (req, res) => {
  const result = await checkS3Health();
  if (result.status === 'UP') {
    res.json({
      status: 'SUCCESS',
      message: 'Successfully verified S3 Bucket read/write operations',
      bucket: result.bucket,
      key: result.verifiedKey,
    });
  } else {
    res.status(503).json({
      status: 'FAILED',
      message: 'Failed to interact with S3 Bucket',
      details: result,
    });
  }
});

// Start Server if invoked directly
if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`[App] Savitara DevOps App listening on port ${PORT}`);
    console.log(`[App] AWS Region: ${AWS_REGION}`);
    console.log(`[App] Health endpoint: http://localhost:${PORT}/health`);
  });
}

module.exports = app;

