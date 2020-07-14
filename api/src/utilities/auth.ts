const data = process.env.AUTH_PUBLIC_KEY || 'testbase64';
let buff = Buffer.alloc(4096, data, 'base64');
const publicKey = buff.toString('ascii');

const jwt = require('jsonwebtoken');

export function verifyJWT(token) {
    return jwt.verify(token, publicKey)
}
