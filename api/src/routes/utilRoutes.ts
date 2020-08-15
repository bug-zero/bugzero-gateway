import {Router} from "express";
import {VpnUserOperations} from "../vpn_operations/user_operations";
import {ResponseStatusCode} from "../types/commonTypes";
import {handleAndLogErrors} from "../utilities/logger_util";

export const utilRouter: Router = Router();

utilRouter.get("/status", async (_request, response) => {

    try {
        let res = await VpnUserOperations.getConnectionStatus()
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