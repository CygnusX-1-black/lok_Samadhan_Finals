/**
 * Lok Samadhan - PM2 Process Configuration
 * For deploying to DigitalOcean Droplets (Ubuntu 22.04 / 24.04)
 */

module.exports = {
  apps: [
    {
      name: 'lok-samadhan-backend',
      script: 'src/server.js',
      instances: 'max', // Cluster mode using all CPU cores
      exec_mode: 'cluster',
      autorestart: true,
      watch: false,
      max_memory_restart: '800M',
      env: {
        NODE_ENV: 'development',
        PORT: 5000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 5000
      },
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      merge_logs: true
    }
  ]
};
