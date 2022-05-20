
const ethereumButton = document.querySelector('.enableEthereumButton');

// After Click button
// check : is already connected to Metamask or not ?
// Yes : go to gameplay.html
// No : connect metamask then go to gameplay.html

ethereumButton.addEventListener('click', async () => {
    let account = await GetAccount();

    if(account != ''){
        console.log(account + " is connected to metamask");
        window.location.href = gamePlay;
    }else {
        console.log("No account connect to Metamask");
    }
});
