import {ResponseStatusCode} from "../types/commonTypes";
import {logger} from "../server";

const data = process.env.AUTH_PUBLIC_KEY || 'testbase64';
let buff = Buffer.from(data, 'base64');
const publicKey = buff.toString('ascii');

const jwt = require('jsonwebtoken');

export function verifyJWT(token) {
    return jwt.verify(token, publicKey)
}

//Extract auth header
export function extractBearerTokenFromHeader(header?: string) {
    if (header && header.length > 1) {
        if (header.startsWith("Bearer ")) {
            return header.substring(7, header.length);
        } else {
            throw Error('Header does not start with Bearer ')
        }
    } else {
        throw Error('Token cannot be extracted')
    }
}

export function checkToken(req: Request, res, next) {

    if (process.env.SKIP_TOKEN_CHECK === '1') {
        return next()
    }
    const bearerHeader = req.headers['authorization'];

    try {
        const token = extractBearerTokenFromHeader(bearerHeader);
        verifyJWT(token)
        next()
    } catch (e) {
        logger.error(e)
        res.sendStatus(ResponseStatusCode.Unauthorized);
    }

}
