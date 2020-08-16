import {connectSSH, ssh} from "../utilities/ssh_conn";
import {logger} from "../server";

export namespace VpnUtilOperations {
    export async function getConnectionStatus(): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }
        const command = `sudo ipsec statusall`
        return await ssh.execCommand(command, {cwd: '/'})
    }

    export async function getCACert(): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }
        const command = `cat /etc/ipsec.d/cacerts/chain.pem`
        return await ssh.execCommand(command, {cwd: '/'})
    }

    export async function getCert(): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }
        const command = `cat /etc/ipsec.d/certs/cert.pem`
        return await ssh.execCommand(command, {cwd: '/'})
    }

    export async function getUbuntuClientConfig(): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }
        const command = `cat /etc/vpn-ubuntu-client.sh`
        return await ssh.execCommand(command, {cwd: '/'})
    }
}
