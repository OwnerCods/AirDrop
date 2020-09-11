pragma solidity 0.5.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}

contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
       
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
 
contract Token is owned {
    

   using SafeMath for uint256;
    string constant public _name = "ATMOSPHERE";
    string constant public _symbol = "AIR";
    uint256 constant private _decimals = 18;
    uint256 private _totalSupply = 21000000 * (10**_decimals);         //21 mln tokens
    uint256 constant public maxSupply = 100000000 * (10**_decimals);    //100 million tokens
    bool public safeguard;  //putting safeguard on will halt all non-owner functions

   
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public frozenAccount;

 bool internal locker;
    
    modifier noReentrant() {
        require (!locker ,"no retrency");
        locker = true;
        _;
        locker = false;
    }   


    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address target, bool frozen);
    
    // This will log approval of token Transfer
    event Approval(address indexed from, address indexed spender, uint256 value);


   
   
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address user) public view returns(uint256){
        return _balanceOf[user];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        
        
        require(!safeguard);
        require (_to != address(0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        
        // overflow and undeflow checked by SafeMath Library
       _balanceOf[_from] = _balanceOf[_from].sub(_value);    // Subtract from the sender
        _balanceOf[_to] = _balanceOf[_to].add(_value);        // Add the same to the recipient
        
        
        emit Transfer(_from, _to, _value);
    }

   
    function transfer(address _to, uint256 _value) public  returns (bool success) {
        
        //no need to check for input validations, as that is ruled by SafeMath
        _transfer(msg.sender, _to, _value);
        return true;
    }

    
    function transferFrom(address _from, address spender, uint256 _value) public returns (bool success) {
        //checking of allowance and token value is done by SafeMath
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
       
        _transfer(_from, spender, _value);
        return true;
    }

   
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!safeguard);
       
        //require(_balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
  
    function increase_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    function decrease_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].sub(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    constructor()  public{
        //sending all the tokens to Owner
        _balanceOf[owner] = _totalSupply;
        
        //firing event which logs this transaction
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    function () external payable {
      buyTokens();
    }


    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        //checking of enough token balance is done by SafeMath
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        _totalSupply = _totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

   
    function burnFrom(address _from, uint256 _value) public returns  (bool success) {
        require(!safeguard);
        //checking of allowance and token value is done by SafeMath
        _balanceOf[_from] = _balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
        _totalSupply = _totalSupply.sub(_value);                                   // Update totalSupply
        emit  Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
        
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }
  
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        require(_totalSupply.add(mintedAmount) <= maxSupply, "Cannot Mint more than maximum supply");
        _balanceOf[target] = _balanceOf[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
    }

  
    
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner noReentrant{
       
        // no need for overflow checking as that will be done in transfer function
        _transfer(address(this), owner, tokenAmount);
    }
    
    //Just in rare case, owner wants to transfer Ether from contract to owner address
     function manualWithdrawEther()onlyOwner public{
         uint share = _balanceOf[msg.sender];
       _balanceOf[msg.sender] = 0;
        msg.sender.transfer(share);
        address(owner).transfer(address(this).balance);
    }
   
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }
    

    
    /*************************************/
    /*    Section for User Air drop      */
    /*************************************/
    
    bool public passiveAirdropStatus;
    uint256 public passiveAirdropTokensAllocation;
    uint256 public airdropAmount;  //in wei
    uint256 public passiveAirdropTokensSold;
    mapping(uint256 => mapping(address => bool)) public airdropClaimed;
    uint256 internal airdropClaimedIndex;
    uint256 public airdropFee = 0.005 ether;
    
  
    function startNewPassiveAirDrop(uint256 passiveAirdropTokensAllocation_, uint256 airdropAmount_  ) public onlyOwner {
        passiveAirdropTokensAllocation = passiveAirdropTokensAllocation_;
        airdropAmount = airdropAmount_;
        passiveAirdropStatus = true;
    } 
    
    function stopPassiveAirDropCompletely() public onlyOwner{
        passiveAirdropTokensAllocation = 0;
        airdropAmount = 0;
        airdropClaimedIndex++;
        passiveAirdropStatus = false;
    }
   
    function claimPassiveAirdrop() public payable returns(bool) {
        require(airdropAmount > 0, 'Token amount must not be zero');
        require(passiveAirdropStatus, 'Air drop is not active');
        require(passiveAirdropTokensSold <= passiveAirdropTokensAllocation, 'Air drop sold out');
        require(!airdropClaimed[airdropClaimedIndex][msg.sender], 'user claimed air drop already');
        require(!isContract(msg.sender),  'No contract address allowed to claim air drop');
        require(msg.value >= airdropFee, 'Not enough ether to claim this airdrop');
        _balanceOf[msg.sender] += airdropAmount;
        _balanceOf[address(this)] -= airdropAmount;
        _transfer(address(this), msg.sender, airdropAmount);
        passiveAirdropTokensSold += airdropAmount;
        airdropClaimed[airdropClaimedIndex][msg.sender] = true; 
        return true;
    }
    
  
    function changePassiveAirdropAmount(uint256 newAmount) public onlyOwner{
        airdropAmount = newAmount;
    }
    
   
    function isContract(address _address) private view returns (bool) {
        uint32 size;
        assembly {size := extcodesize(_address)
          
        } return (size > 0);
        
    }
    
    
    
    function updateAirdropFee(uint256 newFee) public onlyOwner{
        airdropFee = newFee;
    }
   
    function airdropACTIVE(address[] memory recipients,uint256[] memory tokenAmount) public returns(bool) {
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 3,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          //This will loop through all the recipients and send them the specified tokens
          //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
          transfer(recipients[i], tokenAmount[i]);
        }
        return true;
    }
    
    
    /*************************************/
    /*  Section for User whitelisting    */
    /*************************************/
    bool public whitelistingStatus;
    mapping (address => bool) public whitelisted;
    
    
    function changeWhitelistingStatus() onlyOwner public{
        if (whitelistingStatus == false){
            whitelistingStatus = true;
        }
        else{
            whitelistingStatus = false;    
        }
    }
    
  
    function whitelistUser(address userAddress) onlyOwner public{
        require(whitelistingStatus == true);
        require(userAddress != address(0));
        whitelisted[userAddress] = true;
    }
   
    function whitelistManyUsers(address[] memory userAddresses) onlyOwner public{
        require(whitelistingStatus == true);
        uint256 addressCount = userAddresses.length;
        require(addressCount <= 3,"Too many addresses");
        for(uint256 i = 0; i < addressCount; i++){
            whitelisted[userAddresses[i]] = true;
        }
    }
   
    
    uint256 public sellPrice;
    uint256 public buyPrice;
    
   
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;   //sellPrice is 1 Token = ?? WEI
        buyPrice = newBuyPrice;     //buyPrice is 1 ETH = ?? Tokens
    }

    
    function buyTokens() payable public noReentrant {
        require(!isContract(msg.sender),  'No contract address allowed to claim air drop');
        uint amount = msg.value * buyPrice;                 // calculates the amount
        _balanceOf[address(this)] -= amount;
        _transfer(address(this), msg.sender, amount);       // makes the transfers
        
    }

   
    
    function sellTokens(uint256 amount) public {
        uint256 etherAmount = amount * sellPrice/(10**_decimals);
        require(address(this).balance >= etherAmount);   // checks if the contract has enough ether to buy
        
         _transfer( address(this),msg.sender, amount);           // makes the transfers
        msg.sender.transfer(etherAmount);                // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    

}
    