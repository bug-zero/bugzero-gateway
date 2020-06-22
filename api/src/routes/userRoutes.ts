import {MethodResponse} from '../types/commonTypes';
import {UserController} from '../controllers/userController';
import {Router} from 'express';

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


//add the api/deleteuser route
