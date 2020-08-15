import {logger} from "../server";
import {ResponseStatusCode} from "../types/commonTypes";

export function handleAndLogErrors(e, response) {
    logger.error(e)
    if (logger.isDebugEnabled()) {
        return response.status(ResponseStatusCode.InternalError).send({
            responseMessage: 'fail',
            error: e.message
        });
    } else {
        return response.status(ResponseStatusCode.InternalError).send({
            responseMessage: 'fail',
        });
    }
}
