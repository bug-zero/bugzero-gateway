import NodeSSH from 'node-ssh'
import {logger} from "../server";

const ssh = new NodeSSH()


export async function connectSSH() {
    await ssh.connect({
        host: process.env.SSH_HOST,
        username: process.env.SSH_USERNAME,
        password: process.env.SSH_PASSWORD
    })
}

export async function execTest() {

    if (!ssh.connection) {
        await connectSSH()
        logger.info("connected to ssh")
    }

    return new Promise((resolve, reject) => {
        ssh.exec('sudo ls', [], {
            cwd: '/etc/ssh',
            onStdout(chunk) {
                console.log('stdoutChunk', chunk.toString('utf8'))
                resolve(chunk)
            },
            onStderr(chunk) {
                console.log('stderrChunk', chunk.toString('utf8'))
                return reject(chunk)
            },
        })
    })

}
