import {Router} from "express";

import {ResponseStatusCode} from "../types/commonTypes";
import {handleAndLogErrors} from "../utilities/logger_util";
import {VpnUtilOperations} from "../vpn_operations/util_operations";

export const utilRouter: Router = Router();

utilRouter.get("/status", async (_request, response) => {

    try {
        let res = await VpnUtilOperations.getConnectionStatus()
        if (res.code == null || res.code == 0) {
            response.status(ResponseStatusCode.Okay).send({
                responseMessage: 'success',
                payload: res.stdout
            });
        } else {
            response.status(ResponseStatusCode.InternalError).send({
                responseMessage: 'fail',
                payload: res.stderr
            });
        }
    } catch (e) {
        handleAndLogErrors(e, response)
    }
})