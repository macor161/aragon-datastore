import * as async from 'async'
import * as encryption from './encryption-providers'
import * as rpc from './rpc-providers'
import * as storage from './storage-providers'

import { createFileFromTuple } from './utils'



export const providers = { storage, encryption, rpc }

export class DatastoreOptions {
    storageProvider = new providers.storage.Ipfs(null as any)
    encryptionProvider = new providers.encryption.Aes()
    rpcProvider: any
}


export class Datastore {

    private _storage
    private _encryption
    private _rpc
    private _contract
    private _isInit

    /**
     * Creates a new Datastore instance
     * 
     * @param {Object} opts.storageProvider - Storage provider (IPFS, Swarm, Filecoin)
     * @param {Object} opts.rpcProvider - RPC provider (Web3, Aragon)
     * @param {Object} opts.encryptionProvider - Encryption provider for file encryption
     */
    constructor(opts?: DatastoreOptions) {
        opts = Object.assign(new DatastoreOptions(), opts || {})

        this._storage = opts.storageProvider
        this._encryption = opts.encryptionProvider
        this._rpc = opts.rpcProvider
        this._isInit = this.initialize()
    }

    async initialize() {
        // Initialize only once
        if (!this._isInit) {
            this._contract = await this._rpc.getContract()
        }
        else {
            return this._isInit
        }
    }

    /**
     * Add a new file to the Datastore
     * @param {string} name - File name
     * @param {ArrayBuffer} file - File content
     */
    async addFile(name: string, file: ArrayBuffer) {
        await this.initialize()

        const storageId = await this._storage.addFile(file)
        const fileId = await this._contract.addFile(storageId, name, file.byteLength, true)
        return fileId
    }

    /**
     * Returns a file and its content from its Id
     * @param {number} fileId 
     * @returns {Promise<File>}
     */
    async getFile(fileId: number) {
        await this.initialize()

        const fileInfo = await this.getFileInfo(fileId)
        const fileContent = await this._storage.getFile(fileInfo.storageRef)

        return { ...fileInfo, content: fileContent }
    }

    /**
     * Returns the file information without the content
     * @param {number} fileId 
     */
    async getFileInfo(fileId: number) {
        await this.initialize() 

        const fileTuple = await this._contract.getFile(fileId)
        return { id: fileId, ...createFileFromTuple(fileTuple) }
    }

    /**
     * 
     */
    async listFiles() {
        await this.initialize()

        const lastFileId = (await this._contract.lastFileId()).toNumber()
        let files = []
        
        // TODO: Optimize this code
        for (let i = 1; i <= lastFileId; i++) {
            files[i] = await this.getFileInfo(i)
        }

        return files
    }

 
    async setFileContent(fileId: number, file: ArrayBuffer) {
        await this.initialize()
        const storageId = await this._storage.addFile(file)
        await this._contract.setFileContent(fileId, storageId, file.byteLength)

    }

    async setWritePermission(fileId: number, entity: string, hasPermission: boolean) {
        await this.initialize()
        await this._contract.setWritePermission(fileId, entity, hasPermission)
    }

    async setFilename(fileId: number, newName: string) {
        await this.initialize()

        await this._contract.setFilename(fileId, newName)

    }

    async events(...args) {
        await this.initialize()

        return this._contract.events(...args)
    }

}
