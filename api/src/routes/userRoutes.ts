import {MethodResponse, ResponseStatusCode} from '../types/commonTypes';
import {UserController} from '../controllers/userController';
import {Router} from 'express';
import {VpnUserOperations} from "../vpn_operations/user_operations";
import execTest = VpnUserOperations.execTest;
import {handleAndLogErrors} from "../utilities/logger_util";

export const userRouter: Router = Router();

// userRouter.post("/api/adduser", async (request, response) => {
//     let user: string = String(request.body.user);
//     let identity: string = String(request.body.identity);
//     let addUserResponse: MethodResponse = await UserController.
// })

userRouter.get("/userlist", async (_request, response) => {
    //let controllerResponse: MethodResponse = await UserController.getAllUsers();

    try {
        let res = await VpnUserOperations.getAllUsers()
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


});

userRouter.post("/adduser", async (request, response) => {
    let user: string = String(request.body.user);
    let identity: string = String(request.body.identity);
    // let controllerResponse: MethodResponse = await UserController.addUser({
    //     user,
    //     identity
    // })


    try {

        if (!identity || !user)
            throw new Error("Invalid inputs")

        let res = await VpnUserOperations.addUser(user, identity)
        if (res.code == null || res.code == 0) {
            response.status(ResponseStatusCode.Okay).send({
                responseMessage: 'success',
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
});

userRouter.post("/updateidentity", async (request, response) => {
    let userId = request.body._id;
    let identity = request.body.identity;
    let updateResponse: MethodResponse = await UserController.updateUser({
        _id: userId,
        identity
    })
    response.status(updateResponse.status).send({
        responseMessage: updateResponse.responseMessage,
        payload: updateResponse.payload
    });
});

userRouter.post("/test", async (request, response) => {
    if (request.body.id)
        console.log(request.body.id)

    try {
        let a = await execTest()
        console.log(a)
    } catch (e) {
        response.status(400).send({
            success: false
        })
    }


    response.status(200).send({
        success: true
    })
})


userRouter.delete("/delete/:user", async (request, response) => {
    let user: string = String(request.params.user);

    try {

        if (!user)
            throw new Error("Invalid inputs")

        let res = await VpnUserOperations.deleteUser(user)
        if (res.code == null || res.code == 0) {
            response.status(ResponseStatusCode.Okay).send({
                responseMessage: 'success',
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
});
