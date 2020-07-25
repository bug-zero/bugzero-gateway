import {logger} from "../server";
import {connectSSH, ssh} from "../utilities/ssh_conn";

export namespace VpnUserOperations {

    export async function execTest(): Promise<any> {

        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }
        return await ssh.execCommand('sudo sleep 5', {cwd: '/home'})

    }

    export async function addUser(username, secret): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }

        const command = `echo '${username} : EAP "${secret}"' | sudo tee -a /etc/ipsec.secrets`
        return await ssh.execCommand(command, {cwd: '/'})
    }

    export async function getAllUsers(): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }
        return await ssh.execCommand('sudo cat /etc/ipsec.secrets', {cwd: '/'})
    }

    export async function deleteUser(username): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }

        const command = `sudo sed -i '/${username} .*/d' /etc/ipsec.secrets`
        return await ssh.execCommand(command, {cwd: '/'})
    }

}
