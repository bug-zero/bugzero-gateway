import dotenv from 'dotenv';

dotenv.config();
//Keep above at top

import cors from 'cors';
import express from 'express';
import bodyParser from 'body-parser';
import {userRouter} from "./routes/userRoutes";
import {checkToken} from "./utilities/auth";
//import {dbConnect} from "./utilities/dbConnection";
import {getLogger} from 'log4js'
import {utilRouter} from "./routes/utilRoutes";

//Enable global logger
export const logger = getLogger();
logger.level = process.env.LOG_LEVEL || 'info';

//dbConnect().then(_ => logger.info("Database connected")).catch(err => logger.error(err))

const app = express();
const port = process.env.PORT || 3000

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));

app.listen(port, () => {
    logger.info('Server started on port ' + port)
})

app.use("/api/user", checkToken, userRouter);
app.use("/api/util", checkToken, utilRouter);
