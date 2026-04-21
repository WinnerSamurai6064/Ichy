// vercel_api/api/upload/presign.js
// Generates a presigned PUT URL for Cloudflare R2 via S3-compatible API
const crypto = require('crypto');
const { authMiddleware, cors, ok, err } = require('../_lib/db');

const R2_ACCOUNT_ID    = process.env.R2_ACCOUNT_ID;
const R2_ACCESS_KEY_ID = process.env.R2_ACCESS_KEY_ID;
const R2_SECRET        = process.env.R2_SECRET_ACCESS_KEY;
const R2_BUCKET        = process.env.R2_BUCKET_NAME;
const R2_PUBLIC_URL    = process.env.R2_PUBLIC_URL; // e.g. https://pub-xxx.r2.dev

// ── AWS Signature V4 presign (works with R2's S3-compatible API) ───
function presignPut(key, mimeType, expiresIn = 300) {
  const host   = `${R2_BUCKET}.${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
  const region = 'auto';
  const service = 's3';
  const now  = new Date();
  const date  = now.toISOString().replace(/[:-]|\.\d{3}/g, '').slice(0, 8);
  const datetime = now.toISOString().replace(/[:-]|\.\d{3}/g, '').slice(0, 15) + 'Z';

  const credential = `${R2_ACCESS_KEY_ID}/${date}/${region}/${service}/aws4_request`;

  const queryParams = new URLSearchParams({
    'X-Amz-Algorithm':     'AWS4-HMAC-SHA256',
    'X-Amz-Credential':    credential,
    'X-Amz-Date':          datetime,
    'X-Amz-Expires':       String(expiresIn),
    'X-Amz-SignedHeaders': 'content-type;host',
  });

  const canonicalRequest = [
    'PUT',
    '/' + key,
    queryParams.toString(),
    `content-type:${mimeType}\nhost:${host}\n`,
    'content-type;host',
    'UNSIGNED-PAYLOAD',
  ].join('\n');

  const stringToSign = [
    'AWS4-HMAC-SHA256',
    datetime,
    `${date}/${region}/${service}/aws4_request`,
    crypto.createHash('sha256').update(canonicalRequest).digest('hex'),
  ].join('\n');

  const signingKey = ['aws4_request', service, region, date].reduce(
    (key, data) => crypto.createHmac('sha256', key).update(data).digest(),
    Buffer.from(`AWS4${R2_SECRET}`)
  );
  const signature = crypto.createHmac('sha256', signingKey).update(stringToSign).digest('hex');

  queryParams.append('X-Amz-Signature', signature);
  return `https://${host}/${key}?${queryParams.toString()}`;
}

module.exports = async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return err(res, 'Method not allowed', 405);

  const auth = authMiddleware(req);
  if (!auth) return err(res, 'Unauthorized', 401);

  if (!R2_ACCOUNT_ID || !R2_ACCESS_KEY_ID || !R2_SECRET || !R2_BUCKET) {
    return err(res, 'R2 not configured', 500);
  }

  const { mime_type = 'application/octet-stream' } = req.body || {};
  const ext  = mime_type.split('/')[1]?.split('+')[0] || 'bin';
  const key  = `uploads/${auth.userId}/${Date.now()}-${crypto.randomBytes(6).toString('hex')}.${ext}`;

  const upload_url  = presignPut(key, mime_type);
  const public_url  = R2_PUBLIC_URL
    ? `${R2_PUBLIC_URL}/${key}`
    : `https://${R2_BUCKET}.${R2_ACCOUNT_ID}.r2.cloudflarestorage.com/${key}`;

  ok(res, { upload_url, public_url, key });
};
