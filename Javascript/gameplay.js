const web3 = new Web3(Web3.givenProvider);

let allCavers = [];
let chosenCaverId = 0; 
let chosenCaverPickaxe = 0;
let chosenCaverSpace = 0;

(async function(){
    getHomePage();
    
    await CheckMetamask();
    await ShowBalance();

})();

// ----------------------------------------------------------------------------- Onclick

document.querySelector('#get-home-page').onclick = getHomePage;
document.querySelector('#get-caver-page').onclick = getCaverPage;
document.querySelector('#get-backpack-page').onclick = getBackpackPage;
document.querySelector('#get-pickaxe-page').onclick = getPickaxePage;
document.querySelector('#get-mine-page').onclick = getMinePage;
document.querySelector('#get-setting-page').onclick = getSettingPage;

document.getElementById('btn_mintCaver').onclick = MintCaver;
document.getElementById('btn_mintBackpack').onclick = MintBackpack;
document.getElementById('btn_mintPickaxe').onclick = MintPickaxe;

document.getElementById('btn_approve').onclick = GivePlayerApprove;

document.getElementById('btn_equip-backpack').onclick = EquipBackpack;
document.getElementById('btn_equip-pickaxe').onclick = EquipPickaxe;

document.getElementById('btn_buy-consumable').onclick = BuyConsumable;

document.getElementById('btn_claim-reward').onclick = ClaimReward;
// ----------------------------------------------------------------------------- Mint Function
async function MintCaver(){
    ShowLoading("Minting Caver");
    let price = await GetPrice(1);

    if (await !CheckAllowance(price)){
        alert ("Please give allowance first");
        HideLoading();
        return;
    }
    
    let reset = false;
    // Confirmation 
    if (confirm('Confirmation: \n' + 
            'Mint: ' + 1 + ' Caver \n' +
            'Require: ' + price + ' MTK'     
            )
    ){
    // Mint Item
    await ConnectGameplayContract();
    await contract.methods
                    .MintItem(1, 1)
                    .send({from: await GetAccount()})
                    .on("receipt", function(receipt){
                        console.log(receipt);  
                        reset = true;
                    }).catch(function(err){
                        console.log(err);
                    })  
    }

    if(reset){
        await DisplayCaver();
    }

    HideLoading();

}

async function MintBackpack(){
    let amount = document.getElementById("input_backpackAmount").value;
    if (amount <= 0){
        alert ("Please input more than zero amount to mint");
        return;
    }

    ShowLoading("Minting Backpack(s)");
    let price = await GetPrice(2) * amount;

    if (await !CheckAllowance(price)){
        alert ("Please give allowance first");
        HideLoading();
        return;
    }
    let reset = false;
    // Confirmation 
    if (confirm('Confirmation: \n' + 
            'Mint: ' + amount + ' Backpack(s) \n' +
            'Require: ' + price + ' MTK'     
            )
    ){
    // Mint Item
    await ConnectGameplayContract();
    await contract.methods
                  .MintItem(2, amount)
                  .send({from: await GetAccount()})
                  .on("receipt", function(receipt){
                      console.log(receipt);  
                      reset = true;
                  }).catch(function(err){
                      console.log(err);
                  })  
    }

    if(reset){
        // Display Item
        await DisplayBackpack();
    }

    HideLoading();
}

async function MintPickaxe(){
    let amount = document.getElementById("input_pickaxeAmount").value;
    if (amount <= 0){
        alert ("Please input more than zero amount to mint");
        return;
    }

    ShowLoading("Minting Pickaxe(s)");
    let price = await GetPrice(3) * amount;

    if (await !CheckAllowance(price)){
        alert ("Please give allowance first");
        HideLoading();
        return;
    }
    
    let reset = false;
    // Confirmation 
    if (confirm('Confirmation: \n' + 
            'Mint: ' + amount + ' Pickaxe(s) \n' +
            'Require: ' + price + ' MTK'     
            )
    ){
    // Mint Item
    await ConnectGameplayContract();
    await contract.methods
                  .MintItem(3, amount)
                  .send({from: await GetAccount()})
                  .on("receipt", function(receipt){
                      console.log(receipt);  
                      reset = true;
                  }).catch(function(err){
                      console.log(err);
                  })  
    }

    if (reset){
        // Display Item
        await DisplayPickaxe();
    }

    HideLoading();
}

async function DisplayCaver(){
    //get total NFT ny Id
    ShowLoading("Getting all NFTs information");
    let NFTs = await GetNFT(1); 

    //load all attribute each NFT
    await ConnectCaverContract();
    allCavers = [];
    for (let i = 0; i < NFTs.length; i++){
        let id = NFTs[i];
        let item = new NFTCaver(
            "Caver",
            id,
            await contract.methods.nftStrength(id).call(),
            await contract.methods.PickaxeEquippedAmount(id).call(),
            await contract.methods.nftSpace(id).call(),
            await contract.methods.nftSharpens(id).call(),
            await contract.methods.nftFoods(id).call(),
            await contract.methods.tokenURI(id).call()
        )
        allCavers.push(item);
    }

    //Display Each NFT (image + attribute)
    document.getElementById("display_items").innerHTML = "";
    const parent = document.getElementById("display_items");
    for (i=0; i<allCavers.length; i++){
        let nft = allCavers[i];
        let htmlString =`
        <div class="card my-3" style="width: 10rem;">
            <img src="${allCavers[i].url}" class="card-img-top">
            <div class="card-body">
                <h5 class="card-title">${allCavers[i].name}</h5>
                <p class="card-text">
                    ID: ${allCavers[i].id} <br>
                    Str: ${allCavers[i].str} <br>
                    Pickaxe: ${allCavers[i].pickaxes} <br>
                    Free Space: ${allCavers[i].space} <br>
                    Sharpens: ${allCavers[i].sharpens} <br>
                    Foods: ${allCavers[i].foods} <br>
                </p>
                <div class="form-check">
                    <input  class="form-check-input" 
                            type="radio" 
                            value="${allCavers[i].id}" 
                            name="flexRadioDefault" 
                            id="${allCavers[i].id}" 
                            onclick="GetChosenCaver(${allCavers[i].id})"
                            >
                    <label for="${allCavers[i].id}"> Select </label>
                </div>
            </div>
        </div>
        `
        let col = document.createElement("div");
        col.className = "col col-sm-3"
        col.innerHTML = htmlString;
        parent.appendChild(col);
    }
    HideLoading();
}

async function DisplayBackpack(){
    //get total NFT ny Id
    ShowLoading("Getting all NFTs information");
    let NFTs = await GetNFT(2);

    //load all attribute each NFT
    await ConnectBackpackContract();
    let NFTs_att = [];
    for (let i = 0; i < NFTs.length; i++){
        let id = NFTs[i];
        let item = new NFTItem(
            "Backpack",
            id,
            await contract.methods.nftLevel(id).call(),
            await contract.methods.nftSpace(id).call(),
            await contract.methods.tokenURI(id).call()
        )
        NFTs_att.push(item);
    }

    //Display Each NFT (image + attribute)
    _DisplayTools(2, NFTs_att);

    HideLoading();
}

async function DisplayPickaxe(){

    //get total NFT ny Id
    ShowLoading("Getting all NFTs information");
    let NFTs = await GetNFT(3);

    //load all attribute each NFT
    await ConnectPickaxeContract();
    let NFTs_att = [];
    for (let i = 0; i < NFTs.length; i++){
        let id = NFTs[i];
        let item = new NFTItem(
            "Pickaxe",
            id,
            await contract.methods.nftLevel(id).call(),
            await contract.methods.nftStr(id).call(),
            await contract.methods.tokenURI(id).call()
        )
        NFTs_att.push(item);
    }

    //Display Each NFT (image + attribute)
    _DisplayTools(3, NFTs_att);

    HideLoading();
}

async function _DisplayTools(choose, promises){
    document.getElementById("display_items").innerHTML = "";
    const parent = document.getElementById("display_items");
    let att;
    switch(choose){
        case 2: att = "Space";
        break;
        case 3: att = "Str";
        break
    }
    for (i=0; i<promises.length; i++){
        let htmlString =`
        <div class="card my-3" style="width: 10rem;">
            <img src="${promises[i].url}" class="card-img-top" alt="...">
            <div class="card-body">
                <h5 class="card-title">${promises[i].name}</h5>
                <p class="card-text">
                    ID: ${promises[i].id} <br>
                    Lv: ${promises[i].level} <br>
                    ${att}: ${promises[i].att} 
                </p>
                <div class="form-check">
                    <input  type="checkbox" 
                            class="checkbox"  
                            id="${promises[i].id}"
                            value="${promises[i].att}"
                    <label for="${promises[i].id}"> Equip </label>
                </div>
            </div>
        </div>
        `
        let col = document.createElement("div");
        col.className = "col col-sm-3"
        col.innerHTML = htmlString;
        parent.appendChild(col);
    }
}

// ----------------------------------------------------------------------------- Equip Function
async function EquipBackpack(){
    if(chosenCaverId == 0){
        alert("Please select Caver first");
        return;
    }

    let previousSpace = 0;
    let addSpace = 0;
    let newSpace = 0;
    let listItems = [];

    let checkboxes = document.querySelectorAll('.checkbox');
    for (let e of checkboxes){
        if (e.checked == true){
            addSpace += Number(e.defaultValue);
            listItems.push(e.id);
        }
    }

    if(addSpace == 0){
        alert("please select Backpack(s)");
    }

    previousSpace = Number(chosenCaverSpace);
    newSpace = previousSpace + addSpace;

    ShowLoading("Equipping Backpack(s)");
    let reset = false;
    if (confirm('Confirmation: \n' + 
                'Previous space : ' + previousSpace + '\n' +
                'New space: ' + newSpace     )
    ){
        await ConnectGameplayContract();
        await contract.methods
                  .EquipBackpack(listItems, chosenCaverId)
                  .send({from: await GetAccount()})
                  .on("receipt", function(receipt){
                      console.log(receipt);  
                      reset = true;
                  }).catch(function(err){
                      console.log(err);
                  })  
    }

    if (reset){
        //reset chosenCaver
        ResetChosenCaver();
        //reload backpack page
        DisplayBackpack();
    }

    HideLoading();
}

async function EquipPickaxe(){

    if(chosenCaver == 0){
        alert("Please select Caver first");
        return;
    }

    let previousStr = 0;
    let addstr = 0;
    let newstr = 0;
    let listItems = [];

    let checkboxes = document.querySelectorAll('.checkbox');
    for (let e of checkboxes){
        if (e.checked == true){
            addstr += Number(e.defaultValue);
            listItems.push(e.id);
        }
    }

    if(addstr == 0){
        alert("please select Pickaxe(s)");
    }

    //loop to find chosen Caver
    for (i=0; i<allCavers.length; i++){
        if (allCavers[i].id == chosenCaver){
            previousstr = Number(allCavers[i].str);

            newstr = previousstr + addstr;
        }
    }

    ShowLoading("Equipping Pickaxe(s)");
    let reset = false;
    if (confirm('Confirmation: \n' + 
                'Previous str : ' + previousstr + '\n' +
                'New str: ' + newstr     )
    ){
        await ConnectGameplayContract();
        await contract.methods
                  .EquipPickaxe(listItems, chosenCaverId)
                  .send({from: await GetAccount()})
                  .on("receipt", function(receipt){
                      console.log(receipt);  
                      reset = true;
                  }).catch(function(err){
                      console.log(err);
                  }) 
    }

    if (reset){
        //reset chosenCaver
        ResetChosenCaver();
        //reload backpack page
        DisplayPickaxe();
    }

    HideLoading();
}

// ----------------------------------------------------------------------------- Buy Consumable Function
async function BuyConsumable(){    

    //Check choosen caver
    if(chosenCaverId == 0){
        alert("Please select Caver first");
        return;
    }

    let sharpensAmount = document.getElementById('input-sharpens').value;
    let foodsAmount = document.getElementById('input-foods').value;

    // Check input
    if (sharpensAmount == 0 && foodsAmount == 0){
        alert("Please input Sharpens or foods you want to buy");
        return;
    }

    await ShowLoading("Buying consumable");
    let price = await GetPrice(4) * sharpensAmount + (await GetPrice(5) * foodsAmount) / 1000;

    //check allowance
    if (await !CheckAllowance(price)){
        alert ("Please give allowance first");
        HideLoading();
        return;
    }

    let reset = false;

    // Confirmation 
    if (confirm('Confirmation: \n' + 
            'Buy ' + sharpensAmount + ' Sharpens \n' +
            'Buy ' + foodsAmount + ' Foods \n' +
            'Require: ' + price + ' MTK'     
            )
    ){
        // Buy Consumable
        await ConnectGameplayContract();
        await contract.methods
            .BuyConsumable(chosenCaverId, sharpensAmount, foodsAmount)
            .send({from: await GetAccount()})
            .on("receipt", function(receipt){
                console.log(receipt);  
                reset = true;
            }).catch(function(err){
                console.log(err);
            })  
    }

    if (reset){
        ResetChosenCaver();
        document.getElementById('input_sharpens').value = ''
        document.getElementById('input_foods').value = ''
    }

    HideLoading();
}

// ----------------------------------------------------------------------------- Mine Function
async function Mine(level){

    // Check choosen caver
    if(chosenCaverId == 0){
        alert("Please select Caver first");
        return;
    }

    ShowLoading("Mining");

    await ConnectGameplayContract()
    // Check claim reward first
    let claimRewardFirst = await contract.methods.claimRewardFirst(await GetAccount()).call()
    if (claimRewardFirst){
        alert("Please claim your reward before next mine");
        HideLoading();
        return;
    }


    let foodsRequire = []
    let rewardPerLevel = await contract.methods.rewardPerLevel().call()
    for(i=0;i<10;i++){
        let x = ((rewardPerLevel * 5) / 10) * (i+1)
        foodsRequire.push(x)
    }

    let reward = 0;
    let reset = false;

    // Confirmation 
    if (confirm('Confirmation: \n' + 
        'Require ' + (level * 100) + ' Strength \n' +
        'Require ' + chosenCaverPickaxe + ' Sharpens \n' +
        'Require ' + foodsRequire[level-1] + ' Foods \n'
        )
    ){
        // Mine
        await ConnectGameplayContract();
        await contract.methods
            .Mine(chosenCaverId, level)
            .send({from: await GetAccount()})
            .on("receipt", function(receipt){

                console.log(receipt);  
                reward = Number(receipt.events.mined.returnValues.reward) / (10 ** 18); 

            }).catch(function(err){
                console.log(err);
            })  
    }

    if(reset){
        alert("Mine reward: " + reward + " MTK");
        ResetChosenCaver();
    }

    HideLoading();
}

// ----------------------------------------------------------------------------- Claim Reward Function
async function ClaimReward(){
    ShowLoading('Claiming reward');

    await ConnectGameplayContract();

    let myClaimReward = await contract.methods.CalculateReward(await GetAccount()).call()

    //Check if reward is not zero
    if (myClaimReward == 0){
        alert('No reward to claim');
        HideLoading();
        return;
    }

    let reset = false;
    myClaimReward = ( myClaimReward / (10 ** 18) ).toFixed(4);
    // Confirmation 
    if (confirm('Confirmation: \n' + 
        'Claiming ' + myClaimReward + ' MTK'
        )
    ){
        // Mine
        await ConnectGameplayContract();
        await contract.methods
            .ClaimReward()
            .send({from: await GetAccount()})
            .on("receipt", function(receipt){

                console.log(receipt);  
                reset = true;
                //reward = Number(receipt.events.mined.returnValues.reward) / (10 ** 18); 

            }).catch(function(err){
                console.log(err);
            })  
    }

    if(reset){
        alert(myClaimReward + " MTK has been claimed");
        await ShowBalance();
        await getSettingPage();
    }

    HideLoading();
}

// ----------------------------------------------------------------------------- Loading Function
function ShowLoading(status){
    document.getElementById('loading').style.display = "block";
    document.getElementById('loading-status').innerHTML = status + " ...";
}
function HideLoading(){
    document.getElementById('loading').style.display = "none";
}
// ----------------------------------------------------------------------------- Display Function

function getHomePage (){
    DisplayPage("#home-page");
}
function getCaverPage (){
    DisplayPage("#caver-page");
    DisplayCaver();
}
function getBackpackPage (){
    DisplayPage("#backpack-page");
    DisplayBackpack();
}
function getPickaxePage (){
    DisplayPage("#pickaxe-page");
    DisplayPickaxe();
}
function getMinePage (){
    DisplayPage("#mine-page");
}
async function getSettingPage (){
    ShowLoading();

    let approve = await CheckAllowance(10000);
    if (approve){
        document.getElementById("btn_approve").className = "btn btn-primary";
        document.getElementById("btn_approve").innerHTML = "Approved";
        document.getElementById("btn_approve").disabled = true;
    }

    await ConnectGameplayContract();
    document.getElementById("total-reward").innerHTML = (await contract.methods.myReward(await GetAccount()).call() / (10 ** 18)) .toFixed(4) + " MTK";
    document.getElementById("claim-reward-now").innerHTML = (await contract.methods.CalculateReward(await GetAccount()).call() / (10 ** 18)) .toFixed(4) + " MTK";

    DisplayPage("#setting-page");

    HideLoading();
}

// --------------------------------------------------------------------------- Helper function
async function ShowBalance(){
    // Check Balance
    await ConnectTokenContract()
    let myToken = await contract.methods.balanceOf(await GetAccount()).call()
    myToken = (myToken / (10 ** 18) ).toFixed(4)

    // Show Balance
    document.getElementById('token-balance').innerHTML = myToken + ' MTK'
}

async function GetChosenCaver(id){
    ShowLoading("Getting Caver's information");
    await ConnectCaverContract();

    chosenCaverId = 0;
    for (i=0; i<allCavers.length; i++){
        if (allCavers[i].id == id){
            document.getElementById("chosen-caver").style.display = "block";
            document.getElementById("caver-image").src = allCavers[i].url;
            document.getElementById("caver-id").innerHTML = "ID: " + allCavers[i].id;
            document.getElementById("caver-str").innerHTML = "Str: " + allCavers[i].str;
            document.getElementById("caver-pickaxes").innerHTML = "Pickaxes: " + allCavers[i].pickaxes;
            document.getElementById("caver-space").innerHTML = "Space: " + allCavers[i].space;
            document.getElementById("caver-sharpens").innerHTML = "Sharpens: " + allCavers[i].sharpens;
            document.getElementById("caver-foods").innerHTML = "Foods: " + allCavers[i].foods;
            
            chosenCaverId = id;
            chosenCaverPickaxe = allCavers[i].pickaxes;
            chosenCaverSpace = allCavers[i].space;
        }
    }
    if (chosenCaverId != 0){
        document.getElementById("chosen-caver").style.display = "block";
    }else{
        document.getElementById("chosen-caver").style.display = "none";
    }
    HideLoading();
}

function ResetChosenCaver(){
    chosenCaverId = 0;
    document.getElementById("chosen-caver").style.display = "none";
}

