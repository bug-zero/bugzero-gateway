import {MethodResponse} from '../types/commonTypes';
import {UserController} from '../controllers/userController';
import {Router} from 'express';
import {execTest} from "../vpn_operations/user_operations";

export const userRouter: Router = Router();

// userRouter.post("/api/adduser", async (request, response) => {
//     let user: string = String(request.body.user);
//     let identity: string = String(request.body.identity);
//     let addUserResponse: MethodResponse = await UserController.
// })

userRouter.get("/api/userlist", async (_request, response) => {
    let controllerResponse: MethodResponse = await UserController.getAllUsers();
    response.status(controllerResponse.status).send({
        responseMessage: controllerResponse.responseMessage,
        payload: controllerResponse.payload
    });
});

userRouter.post("/api/adduser", async (request, response) => {
    let user: string = String(request.body.user);
    let identity: string = String(request.body.identity);
    let controllerResponse: MethodResponse = await UserController.addUser({
        user,
        identity
    })
    response.status(controllerResponse.status).send({
        responseMessage: controllerResponse.responseMessage,
        payload: controllerResponse.payload
    });
});

userRouter.post("/api/updateidentity", async (request, response) => {
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
    console.log(request.body.id)

    await execTest()

    response.status(200).send({
        success: true
    })
})

//add the api/deleteuser route
