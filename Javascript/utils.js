const gamePlay = 'gameplay.html'
const index = 'index.html'

// Smart Contract Address
const CAVER_ADDRESS = '0xa3F74f56785862cB92700BE60e07BE6Ad0e94D2e'
const BACKPACK_ADDRESS = '0xAf995528d81dDB9E7eA72c85E41CF0d32FF82Aa5'
const PICKAXE_ADDRESS = '0x56a0c49923cF4FFd53621F71FE0801e5444b78ac'
const GAMEPLAY_ADDRESS = '0x9F00f1ee56009Ce1602A3c835055eE5547D41feD' // old 0x5Ab61042682FaDe14eb9502Eb12517eF9D806a22
const TOKEN_ADDRESS = '0x5e6C055331122A6EA75b39cC0b5F4D6E36F9866f'
const POOL_ADDRESS = '0xb8DE0C06A0d55584e7DA4148F352Ed9fF4595367'
const GETRANDOM_ADDRESS = '0xED38F7494Aef3BC7f20C4a768A42D9A15C449433'

const maxTokenApprove = '115792089237316195423570985008687907853269984665640564039457584007913129639935'

// ----------------------------------------------------------------------------
async function ConnectCaverContract(){
    window.contract = new web3.eth.Contract(caverAbi, CAVER_ADDRESS);
}
async function ConnectBackpackContract(){
    window.contract = new web3.eth.Contract(backpackAbi, BACKPACK_ADDRESS);
}
async function ConnectPickaxeContract(){
    window.contract = new web3.eth.Contract(pickaxeAbi, PICKAXE_ADDRESS);
}
async function ConnectGameplayContract(){
    window.contract = new web3.eth.Contract(gameplayAbi, GAMEPLAY_ADDRESS);
}
async function ConnectTokenContract(){
    window.contract = new web3.eth.Contract(tokenAbi, TOKEN_ADDRESS);
}
async function ConnectGetRandomContract(){
    window.contract = new web3.eth.Contract(getRandomAbi, GETRANDOM_ADDRESS);
}
// ---------------------------------------------------------------------------- Smart Contract Preparation
//  1. Gameplay give Whitelist >> Caver, Bacpack, Pickaxe
async function GiveCaverWhitelist (){
    await ConnectCaverContract();
    await contract.methods.setWhitelists(GAMEPLAY_ADDRESS, true).send({from: await GetAccount()})
    console.log("Caver whitelisted")
}
async function GiveBackpackWhitelist (){
    await ConnectBackpackContract();
    await contract.methods.setWhitelists(GAMEPLAY_ADDRESS, true).send({from: await GetAccount()})
    console.log("Backpack whitelisted")
}
async function GivePickaxeWhitelist (){
    await ConnectPickaxeContract();
    await contract.methods.setWhitelists(GAMEPLAY_ADDRESS, true).send({from: await GetAccount()})
    console.log("Pickaxe whitelisted")
}

// 2. Pool Contract Give Approve >> Gameplay
async function GivePoolApprove (){
    await ConnectTokenContract();
    await contract.methods.approve(GAMEPLAY_ADDRESS, maxTokenApprove).send({from: await GetAccount()})
    console.log("Pool approved")
}

// 3. Player Give Approve >> Gameplay
async function GivePlayerApprove (){
    await ConnectTokenContract();
    await contract.methods.approve(GAMEPLAY_ADDRESS, maxTokenApprove).send({from: await GetAccount()})
    console.log("Player's account approved")
}
// ----------------------------------------------------------------------------
async function GetAccount(){
    let accounts = [];
    try {
        //accounts = await ethereum.request({ method: 'eth_requestAccounts' }); --> Return all small letter
        let accounts = await web3.eth.getAccounts();
        let account = accounts[0];

        return(account);

    }catch(error){
        return('');
    }
}

async function CheckMetamask(){
    let account = await GetAccount();

    if(account != ''){
        console.log(account + " has connected to metamask");
        //Show Account Address
        let shortAccount = account.substr(2, 3) + '&hellip;' + account.substr(account.length-3, account.length) ;
        document.getElementById('get-setting-page').innerHTML = shortAccount;
    }else {
        console.log("No account connect to Metamask");
        window.location.href = index;
    }
}
// ----------------------------------------------------------------------------

async function GetNFT(choose){
    let result = [];
    let player = await GetAccount();

    switch(choose){
        case 1: await ConnectCaverContract();
        break;
        case 2: await ConnectBackpackContract();
        break;
        case 3: await ConnectPickaxeContract();
        break;
    }
    let total = await contract.methods.totalSupply().call();
    for (let i = 1; i <= total; i++){ //token start from id 1
        let owner = await await contract.methods.ownerOf(i).call();
        if(owner == player){
            result.push(i);
        }
    }
    return result;
}

async function GetPrice(choose) {
    await ConnectGameplayContract();
    let itemPrice = 0;
    if(choose == 1){ // Caver
        itemPrice = await contract.methods.caverPrice().call();
    }
    else if(choose == 2){ // Backpack
        itemPrice = await contract.methods.backpackPrice().call();
    }
    else if(choose == 3){ // Pickaxe
        itemPrice = await contract.methods.pickaxePrice().call();
    } 
    else if(choose == 4){ // Sharpen
        itemPrice = await contract.methods.sharpenPrice().call();
    } 
    else if(choose == 5){ // food
        itemPrice = await contract.methods.foodPrice().call();
    } 
    
    return(itemPrice);
}
async function CheckAllowance(amount){
    amount = amount * 10 * 18; // convert amount to token with 18 digits
    await ConnectTokenContract();
    let allowance = await contract.methods.allowance(await GetAccount(), GAMEPLAY_ADDRESS).call();
    if (allowance >= amount){
        
        return true;
    }
    else {
        
        return false;
    }
}

// -----------------------------------------------------------------------------

function DisplayPage(choose) {
    document.getElementById("display_items").innerHTML = "";

    let choice = [  
                    '#home-page',
                    '#caver-page',
                    '#backpack-page',
                    '#pickaxe-page',
                    '#mine-page',
                    '#setting-page'
                ]
    choice.forEach(e => {
        // hide all page
        document.querySelector(e).style.display = 'none';
    })
    document.querySelector(choose).style.display = 'block';
}

class NFTItem {
    constructor(name, id, level, att, url){
        this.name = name;
        this.id = id;
        this.level = level;
        this.att = att;
        this.url = url;
    }
}

class NFTCaver {
    constructor(name, id, str, pickaxes, space, sharpens, foods, url) {
        this.name = name;
        this.id = id;
        this.str = str;
        this.pickaxes = pickaxes;
        this.space = space;
        this.sharpens = sharpens;
        this.foods = foods;
        this.url = url;
    }
}