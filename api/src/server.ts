import dotenv from 'dotenv';

dotenv.config();
//Keep above at top

import cors from 'cors';
import express from 'express';
import bodyParser from 'body-parser';
import {userRouter} from "./routes/userRoutes";


const app = express();
const port = process.env.PORT || 4000

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));

app.listen(port, () => {
    console.log('Server started on port ' + port)
})

app.use("/user", userRouter);
