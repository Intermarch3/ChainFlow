// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ChainflowContract, ChainflowPayment} from "../src/Chainflow.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Mock du token ERC20 pour les tests
contract MockERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, 1000000 * 10**18);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address spender, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, spender, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// Contrats mock pour les interfaces Chainlink pour les tests
contract MockAutomationRegistrar {
    uint256 private _upkeepCounter = 0;

    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256) {
        _upkeepCounter++;
        return _upkeepCounter;
    }
}

contract MockAutomationRegistry {
    function cancelUpkeep(uint256 id) external {}
    function withdrawFunds(uint256 id, address to) external {}
}

contract ChainFlowTests is Test {
    ChainflowContract public CFContract;
    ChainflowPayment public CFPayment;
    MockERC20 public mockLink;
    MockERC20 public mockERC20;
    MockAutomationRegistrar public mockRegistrar;
    MockAutomationRegistry public mockRegistry;

    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public recipient = address(0x3);
    address private constant ZERO_ADDRESS = address(0);

    // Adresse réelles de Sepolia (à utiliser si nécessaire)
    address public constant SEPOLIA_LINK_TOKEN = 0x779877a7b0d9e8603169ddbd7836e478b4624789;
    address public constant SEPOLIA_REGISTRAR = 0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976;
    address public constant SEPOLIA_REGISTRY = 0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad;

    event ChainflowNewSubscription(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 index,
        uint96 amount,
        uint256 startInterval,
        uint256 interval,
        uint96 nbPayments
    );

    event ChainflowSubscriptionLastPayment(
        address indexed from,
        uint256 index,
        uint256 timestamp
    );

    event ChainflowSubscriptionCanceled(
        address indexed from,
        uint256 index,
        uint256 timestamp
    );

    event ChainflowSubscriptionPaused(
        address indexed from,
        uint256 index,
        uint256 timestamp
    );

    event ChainflowSubscriptionResumed(
        address indexed from,
        uint256 index,
        uint256 timestamp
    );

    event ChainflowPaymentSent(
        address token,
        uint256 amount,
        address from,
        address to,
        uint256 timestamp
    );

    function setUp() public {
        // Création des contrats mock
        mockLink = new MockERC20("Mock Link", "mLINK");
        mockERC20 = new MockERC20("Mock Token", "mTKN");
        mockRegistrar = new MockAutomationRegistrar();
        mockRegistry = new MockAutomationRegistry();

        // Déploiement des contrats à tester
        CFPayment = new ChainflowPayment();
        CFContract = new ChainflowContract(
            payable(address(CFPayment)),
            address(mockRegistrar),
            address(mockRegistry),
            address(mockLink)
        );

        // Configuration des comptes de test avec des fonds
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(recipient, 1 ether);
        vm.deal(address(CFPayment), 1 ether);
        
        // Transfert des tokens mock aux utilisateurs de test
        mockLink.transfer(user1, 10000 * 10**18);
        mockLink.transfer(user2, 10000 * 10**18);
        mockERC20.transfer(user1, 10000 * 10**18);
        mockERC20.transfer(user2, 10000 * 10**18);
        
        // Configuration du paiement ChainFlow
        vm.startPrank(address(CFPayment));
        CFPayment.setDedicatedMsgSender(address(CFContract));
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////
    //                                                      //
    //                  Utility Functions                   //
    //                                                      //
    //////////////////////////////////////////////////////////
    
    function _createSubscription(
        address user,
        address token,
        uint96 amount,
        uint256 interval,
        uint256 startInterval,
        uint96 linkAmount,
        uint96 nbPayments
    ) internal returns (uint256) {
        vm.startPrank(user);
        
        if (token == ZERO_ADDRESS) {
            // Pour ETH
            mockLink.approve(address(CFContract), linkAmount);
            uint256 upkeepId = CFContract.newSubscription{value: amount}(
                token,
                amount,
                recipient,
                interval,
                startInterval,
                linkAmount,
                nbPayments
            );
            vm.stopPrank();
            return upkeepId;
        } else {
            // Pour token ERC20
            mockLink.approve(address(CFContract), linkAmount);
            IERC20(token).approve(address(CFContract), amount);
            uint256 upkeepId = CFContract.newSubscription(
                token,
                amount,
                recipient,
                interval,
                startInterval,
                linkAmount,
                nbPayments
            );
            vm.stopPrank();
            return upkeepId;
        }
    }

    function _createEthSubscription() internal returns (uint256) {
        return _createSubscription(
            user1,
            ZERO_ADDRESS,
            1 ether,
            60,  // 1 minute interval
            10,  // 10 seconds delay before first payment
            1 * 10**18, // 1 LINK
            5   // 5 payments total
        );
    }

    function _createERC20Subscription() internal returns (uint256) {
        return _createSubscription(
            user1,
            address(mockERC20),
            100 * 10**18,
            60,  // 1 minute interval
            10,  // 10 seconds delay before first payment
            1 * 10**18, // 1 LINK
            5   // 5 payments total
        );
    }

    //////////////////////////////////////////////////////////
    //                                                      //
    //               Constructor and Getters                //
    //                                                      //
    //////////////////////////////////////////////////////////

    function test_constructor() public {
        assertEq(address(CFContract.owner()), address(this));
        assertEq(address(CFContract.linkToken()), address(mockLink));
        assertEq(address(CFContract.chainlinkRegistery()), address(mockRegistry));
        assertEq(address(CFContract.chainlinkRegistrar()), address(mockRegistrar));
        assertEq(address(CFContract.getPaymentContract()), address(CFPayment));
    }

    function test_getPaymentContract() public {
        assertEq(address(CFPayment), CFContract.getPaymentContract());
    }

    //////////////////////////////////////////////////////////
    //                                                      //
    //                  Setters Functions                   //
    //                                                      //
    //////////////////////////////////////////////////////////

    function test_setPaymentContract() public {
        // Seul le propriétaire peut définir le contrat de paiement
        address newPaymentContract = address(0x123);
        
        // Test avec un utilisateur non autorisé
        vm.startPrank(user1);
        vm.expectRevert("Only owner can set payment contract");
        CFContract.setPaymentContract(payable(newPaymentContract));
        vm.stopPrank();

        // Test avec le propriétaire
        CFContract.setPaymentContract(payable(newPaymentContract));
        assertEq(CFContract.getPaymentContract(), newPaymentContract);
    }

    function test_setChainlinkRegistrar() public {
        // Seul le propriétaire peut définir le registrar Chainlink
        address newRegistrar = address(0x123);
        
        // Test avec un utilisateur non autorisé
        vm.startPrank(user1);
        vm.expectRevert("Only owner can set chainlink registrar");
        CFContract.setChainlinkRegistrar(newRegistrar);
        vm.stopPrank();

        // Test avec le propriétaire
        CFContract.setChainlinkRegistrar(newRegistrar);
        assertEq(address(CFContract.chainlinkRegistrar()), newRegistrar);
    }

    function test_setChainlinkRegistery() public {
        // Seul le propriétaire peut définir le registry Chainlink
        address newRegistry = address(0x123);
        
        // Test avec un utilisateur non autorisé
        vm.startPrank(user1);
        vm.expectRevert("Only owner can set chainlink registery");
        CFContract.setChainlinkRegistery(newRegistry);
        vm.stopPrank();

        // Test avec le propriétaire
        CFContract.setChainlinkRegistery(newRegistry);
        assertEq(address(CFContract.chainlinkRegistery()), newRegistry);
    }

    function test_setLinkToken() public {
        // Seul le propriétaire peut définir le token LINK
        address newLinkToken = address(0x123);
        
        // Test avec un utilisateur non autorisé
        vm.startPrank(user1);
        vm.expectRevert("Only owner can set link token");
        CFContract.setLinkToken(newLinkToken);
        vm.stopPrank();

        // Test avec le propriétaire
        CFContract.setLinkToken(newLinkToken);
        assertEq(address(CFContract.linkToken()), newLinkToken);
    }

    //////////////////////////////////////////////////////////
    //                                                      //
    //                Subscription Functions                //
    //                                                      //
    //////////////////////////////////////////////////////////

    function test_newSubscription_ETH() public {
        uint96 amount = 1 ether;
        uint256 interval = 60; // 1 minute
        uint256 startInterval = 10; // 10 seconds delay
        uint96 linkAmount = 1 * 10**18; // 1 LINK
        uint96 nbPayments = 5;

        vm.startPrank(user1);
        mockLink.approve(address(CFContract), linkAmount);

        // Vérifier l'événement émis lors de la création de l'abonnement
        vm.expectEmit(true, true, true, false);
        emit ChainflowNewSubscription(
            user1,
            recipient,
            ZERO_ADDRESS,
            0, // Premier abonnement, donc index = 0
            amount,
            startInterval,
            interval,
            nbPayments
        );

        uint256 upkeepId = CFContract.newSubscription{value: amount}(
            ZERO_ADDRESS,
            amount,
            recipient,
            interval,
            startInterval,
            linkAmount,
            nbPayments
        );
        vm.stopPrank();

        // Vérifier que l'ID Upkeep a été retourné correctement
        assertGt(upkeepId, 0);

        // Vérifier les détails de l'abonnement
        vm.startPrank(user1);
        uint256[] memory subscriptions = CFContract.getMySubscriptions(user1);
        assertEq(subscriptions.length, 1);
        
        // Vérification des détails de l'abonnement
        ChainflowContract.Subscription memory sub = CFContract.getSubscription(subscriptions[0]);
        assertEq(sub.active, true);
        assertEq(sub.paused, false);
        assertEq(sub.interval, interval);
        // N'évaluez pas nextPayment car il dépend du timestamp actuel
        assertEq(sub.token, ZERO_ADDRESS);
        assertEq(sub.amount, amount);
        assertEq(sub.to, recipient);
        assertEq(sub.from, user1);
        assertEq(sub.upKeepId, upkeepId);
        assertEq(sub.nbPayments, nbPayments);
        assertEq(sub.nbPaymentsDone, 0);
        vm.stopPrank();
    }

    function test_newSubscription_ERC20() public {
        uint96 amount = 100 * 10**18;
        uint256 interval = 60; // 1 minute
        uint256 startInterval = 10; // 10 seconds delay
        uint96 linkAmount = 1 * 10**18; // 1 LINK
        uint96 nbPayments = 5;

        vm.startPrank(user1);
        mockLink.approve(address(CFContract), linkAmount);
        mockERC20.approve(address(CFContract), amount);

        // Vérifier l'événement émis lors de la création de l'abonnement
        vm.expectEmit(true, true, true, false);
        emit ChainflowNewSubscription(
            user1,
            recipient,
            address(mockERC20),
            0, // Premier abonnement, donc index = 0
            amount,
            startInterval,
            interval,
            nbPayments
        );

        uint256 upkeepId = CFContract.newSubscription(
            address(mockERC20),
            amount,
            recipient,
            interval,
            startInterval,
            linkAmount,
            nbPayments
        );
        vm.stopPrank();

        // Vérifier que l'ID Upkeep a été retourné correctement
        assertGt(upkeepId, 0);

        // Vérifier les détails de l'abonnement
        vm.startPrank(user1);
        uint256[] memory subscriptions = CFContract.getMySubscriptions(user1);
        assertEq(subscriptions.length, 1);
        
        // Vérification des détails de l'abonnement
        ChainflowContract.Subscription memory sub = CFContract.getSubscription(subscriptions[0]);
        assertEq(sub.active, true);
        assertEq(sub.paused, false);
        assertEq(sub.interval, interval);
        // N'évaluez pas nextPayment car il dépend du timestamp actuel
        assertEq(sub.token, address(mockERC20));
        assertEq(sub.amount, amount);
        assertEq(sub.to, recipient);
        assertEq(sub.from, user1);
        assertEq(sub.upKeepId, upkeepId);
        assertEq(sub.nbPayments, nbPayments);
        assertEq(sub.nbPaymentsDone, 0);
        vm.stopPrank();
    }

    function test_newSubscription_InvalidAmount() public {
        uint96 amount = 0; // Montant invalide
        uint256 interval = 60;
        uint256 startInterval = 10;
        uint96 linkAmount = 1 * 10**18;
        uint96 nbPayments = 5;

        vm.startPrank(user1);
        mockLink.approve(address(CFContract), linkAmount);

        vm.expectRevert("Amount must be greater than 0");
        CFContract.newSubscription(
            ZERO_ADDRESS,
            amount,
            recipient,
            interval,
            startInterval,
            linkAmount,
            nbPayments
        );
        vm.stopPrank();
    }

    function test_newSubscription_InvalidInterval() public {
        uint96 amount = 1 ether;
        uint256 interval = 0; // Intervalle invalide
        uint256 startInterval = 10;
        uint96 linkAmount = 1 * 10**18;
        uint96 nbPayments = 5;

        vm.startPrank(user1);
        mockLink.approve(address(CFContract), linkAmount);

        vm.expectRevert("Interval must be greater than 0");
        CFContract.newSubscription{value: amount}(
            ZERO_ADDRESS,
            amount,
            recipient,
            interval,
            startInterval,
            linkAmount,
            nbPayments
        );
        vm.stopPrank();
    }

    function test_pauseSubscription() public {
        // Créer un abonnement d'abord
        uint256 upkeepId = _createEthSubscription();
        
        vm.startPrank(user1);
        // Vérifier l'événement
        vm.expectEmit(true, false, false, false);
        emit ChainflowSubscriptionPaused(user1, 0, block.timestamp);
        
        uint256 returnedUpkeepId = CFContract.pauseSubscription(0);
        vm.stopPrank();
        
        // Vérifier que l'upkeepId retourné correspond
        assertEq(returnedUpkeepId, upkeepId);
        
        // Vérifier que l'abonnement est en pause
        vm.startPrank(user1);
        ChainflowContract.Subscription memory sub = CFContract.getSubscription(0);
        assertEq(sub.paused, true);
        assertEq(sub.active, true); // Toujours actif
        vm.stopPrank();
    }

    function test_pauseSubscription_NotOwner() public {
        // Créer un abonnement d'abord
        _createEthSubscription();
        
        // Essayer de mettre en pause en tant que non-propriétaire
        vm.startPrank(user2);
        vm.expectRevert("You are not the owner of this subscription");
        CFContract.pauseSubscription(0);
        vm.stopPrank();
    }

    function test_pauseSubscription_AlreadyPaused() public {
        // Créer et mettre en pause un abonnement
        _createEthSubscription();
        
        vm.startPrank(user1);
        CFContract.pauseSubscription(0);
        
        // Essayer de mettre en pause à nouveau
        vm.expectRevert("Subscription is already paused");
        CFContract.pauseSubscription(0);
        vm.stopPrank();
    }

    function test_resumeSubscription() public {
        // Créer et mettre en pause un abonnement
        uint256 upkeepId = _createEthSubscription();
        
        vm.startPrank(user1);
        CFContract.pauseSubscription(0);
        
        // Reprendre l'abonnement
        vm.expectEmit(true, false, false, false);
        emit ChainflowSubscriptionResumed(user1, 0, block.timestamp);
        
        uint256 returnedUpkeepId = CFContract.resumeSubscription(0);
        vm.stopPrank();
        
        // Vérifier que l'upkeepId retourné correspond
        assertEq(returnedUpkeepId, upkeepId);
        
        // Vérifier que l'abonnement n'est plus en pause
        vm.startPrank(user1);
        ChainflowContract.Subscription memory sub = CFContract.getSubscription(0);
        assertEq(sub.paused, false);
        assertEq(sub.active, true);
        vm.stopPrank();
    }

    function test_resumeSubscription_NotOwner() public {
        // Créer et mettre en pause un abonnement
        _createEthSubscription();
        
        vm.startPrank(user1);
        CFContract.pauseSubscription(0);
        vm.stopPrank();
        
        // Essayer de reprendre en tant que non-propriétaire
        vm.startPrank(user2);
        vm.expectRevert("You are not the owner of this subscription");
        CFContract.resumeSubscription(0);
        vm.stopPrank();
    }

    function test_resumeSubscription_NotPaused() public {
        // Créer un abonnement (pas en pause)
        _createEthSubscription();
        
        // Essayer de reprendre un abonnement qui n'est pas en pause
        vm.startPrank(user1);
        vm.expectRevert("Subscription is not paused");
        CFContract.resumeSubscription(0);
        vm.stopPrank();
    }

    function test_cancelSubscription() public {
        // Créer un abonnement
        uint256 upkeepId = _createEthSubscription();
        
        vm.startPrank(user1);
        // Vérifier l'événement
        vm.expectEmit(true, false, false, false);
        emit ChainflowSubscriptionCanceled(user1, 0, block.timestamp);
        
        uint256 returnedUpkeepId = CFContract.cancelSubscription(0);
        vm.stopPrank();
        
        // Vérifier que l'upkeepId retourné correspond
        assertEq(returnedUpkeepId, upkeepId);
        
        // Vérifier que l'abonnement n'est plus actif
        vm.startPrank(user1);
        ChainflowContract.Subscription memory sub = CFContract.getSubscription(0);
        assertEq(sub.active, false);
        
        // Vérifier que l'abonnement n'apparaît plus dans getMySubscriptions
        uint256[] memory subscriptions = CFContract.getMySubscriptions(user1);
        assertEq(subscriptions.length, 0);
        vm.stopPrank();
    }

    function test_cancelSubscription_NotOwner() public {
        // Créer un abonnement
        _createEthSubscription();
        
        // Essayer d'annuler en tant que non-propriétaire
        vm.startPrank(user2);
        vm.expectRevert("You are not the owner of this subscription");
        CFContract.cancelSubscription(0);
        vm.stopPrank();
    }

    function test_cancelSubscription_AlreadyCanceled() public {
        // Créer et annuler un abonnement
        _createEthSubscription();
        
        vm.startPrank(user1);
        CFContract.cancelSubscription(0);
        
        // Essayer d'annuler à nouveau
        vm.expectRevert("Subscription is not active");
        CFContract.cancelSubscription(0);
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////
    //                                                      //
    //                  Chainlink Functions                 //
    //                                                      //
    //////////////////////////////////////////////////////////

    function test_checkUpkeep_NotNeeded() public {
        // Créer un abonnement qui ne nécessite pas encore de paiement
        _createEthSubscription();
        
        // checkUpkeep avec des données encodées
        bytes memory checkData = abi.encode(0); // index 0
        (bool upkeepNeeded, ) = CFContract.checkUpkeep(checkData);
        
        // L'upkeep ne devrait pas être nécessaire car startInterval = 10 secondes
        assertEq(upkeepNeeded, false);
    }

    function test_checkUpkeep_Needed() public {
        // Créer un abonnement
        _createEthSubscription();
        
        // Avancer le temps au-delà de l'intervalle de début
        vm.warp(block.timestamp + 15); // startInterval était de 10 secondes
        
        // checkUpkeep avec des données encodées
        bytes memory checkData = abi.encode(0); // index 0
        (bool upkeepNeeded, bytes memory performData) = CFContract.checkUpkeep(checkData);
        
        // L'upkeep devrait maintenant être nécessaire
        assertEq(upkeepNeeded, true);
        assertEq(performData, checkData);
    }

    function test_checkUpkeep_Paused() public {
        // Créer un abonnement et le mettre en pause
        _createEthSubscription();
        
        vm.startPrank(user1);
        CFContract.pauseSubscription(0);
        vm.stopPrank();
        
        // Avancer le temps au-delà de l'intervalle de début
        vm.warp(block.timestamp + 15);
        
        // checkUpkeep avec des données encodées
        bytes memory checkData = abi.encode(0);
        (bool upkeepNeeded, ) = CFContract.checkUpkeep(checkData);
        
        // L'upkeep ne devrait pas être nécessaire car l'abonnement est en pause
        assertEq(upkeepNeeded, false);
    }

    function test_checkUpkeep_Canceled() public {
        // Créer un abonnement et l'annuler
        _createEthSubscription();
        
        vm.startPrank(user1);
        CFContract.cancelSubscription(0);
        vm.stopPrank();
        
        // Avancer le temps au-delà de l'intervalle de début
        vm.warp(block.timestamp + 15);
        
        // checkUpkeep avec des données encodées
        bytes memory checkData = abi.encode(0);
        (bool upkeepNeeded, ) = CFContract.checkUpkeep(checkData);
        
        // L'upkeep ne devrait pas être nécessaire car l'abonnement est annulé
        assertEq(upkeepNeeded, false);
    }

    function test_performUpkeep_ETH() public {
        // Créer un abonnement ETH
        _createEthSubscription();
        
        // S'assurer que CFPayment a des fonds ETH pour effectuer le paiement
        vm.deal(user1, 10 ether);
        vm.startPrank(user1);
        // Envoyer des ETH au contrat de paiement de l'utilisateur (user1 est l'adresse "from" de l'abonnement)
        (bool sent, ) = payable(user1).call{value: 5 ether}("");
        require(sent, "Failed to send ETH");
        vm.stopPrank();
        
        // Avancer le temps au-delà de l'intervalle de début
        vm.warp(block.timestamp + 15);
        
        // Encoder les données pour performUpkeep
        bytes memory performData = abi.encode(0); // index 0
        
        // Exécuter performUpkeep
        CFContract.performUpkeep(performData);
        
        // Vérifier que l'abonnement a été mis à jour
        vm.startPrank(user1);
        ChainflowContract.Subscription memory sub = CFContract.getSubscription(0);
        assertEq(sub.nbPaymentsDone, 1);
        // Le prochain paiement devrait être dans 60 secondes (interval)
        assertEq(sub.nextPayment, block.timestamp - 15 + 10 + 60);
        assertEq(sub.lastPaymentTimestamp, block.timestamp);
        vm.stopPrank();
    }

    function test_performUpkeep_ERC20() public {
        // Créer un abonnement ERC20
        _createERC20Subscription();
        
        // Avancer le temps au-delà de l'intervalle de début
        vm.warp(block.timestamp + 15);
        
        // Encoder les données pour performUpkeep
        bytes memory performData = abi.encode(0); // index 0
        
        // Exécuter performUpkeep
        CFContract.performUpkeep(performData);
        
        // Vérifier que l'abonnement a été mis à jour
        vm.startPrank(user1);
        ChainflowContract.Subscription memory sub = CFContract.getSubscription(0);
        assertEq(sub.nbPaymentsDone, 1);
        // Le prochain paiement devrait être dans 60 secondes (interval)
        assertEq(sub.nextPayment, block.timestamp - 15 + 10 + 60);
        assertEq(sub.lastPaymentTimestamp, block.timestamp);
        vm.stopPrank();
    }

    function test_performUpkeep_LastPayment() public {
        // Créer un abonnement avec nbPayments = 1
        vm.startPrank(user1);
        mockLink.approve(address(CFContract), 1 * 10**18);
        CFContract.newSubscription{value: 1 ether}(
            ZERO_ADDRESS,
            1 ether,
            recipient,
            60,  // 1 minute interval
            10,  // 10 seconds delay before first payment
            1 * 10**18, // 1 LINK
            1   // 1 payment total
        );
        vm.stopPrank();
        
        // Avancer le temps au-delà de l'intervalle de début
        vm.warp(block.timestamp + 15);
        
        // Encoder les données pour performUpkeep
        bytes memory performData = abi.encode(0); // index 0
        
        // Vérifier l'événement de dernier paiement
        vm.expectEmit(true, false, false, false);
        emit ChainflowSubscriptionLastPayment(user1, 0, block.timestamp);
        
        // Exécuter performUpkeep
        CFContract.performUpkeep(performData);
        
        // Vérifier que l'abonnement a été désactivé
        vm.startPrank(user1);
        ChainflowContract.Subscription memory sub = CFContract.getSubscription(0);
        assertEq(sub.nbPaymentsDone, 1);
        assertEq(sub.active, false); // Devrait être désactivé après le dernier paiement
        
        // Vérifier que l'abonnement n'apparaît plus dans getMySubscriptions
        uint256[] memory subscriptions = CFContract.getMySubscriptions(user1);
        assertEq(subscriptions.length, 0);
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////
    //                                                      //
    //                  ChainflowPayment Tests              //
    //                                                      //
    //////////////////////////////////////////////////////////

    function test_setDedicatedMsgSender() public {
        address newMsgSender = address(0x456);
        ChainflowPayment newPayment = new ChainflowPayment();
        
        // Test avec un appelant non autorisé
        vm.startPrank(user1);
        vm.expectRevert("Only EOA Owner can set its own dedicatedMsgSender");
        newPayment.setDedicatedMsgSender(newMsgSender);
        vm.stopPrank();
        
        // Test avec l'appelant autorisé (le contrat lui-même)
        vm.startPrank(address(newPayment));
        newPayment.setDedicatedMsgSender(newMsgSender);
        vm.stopPrank();
        
        // Vérification indirecte via sendToken
        vm.startPrank(newMsgSender);
        newPayment.sendToken(ZERO_ADDRESS, 0, payable(recipient));
        vm.stopPrank();
        
        // Si le test arrive ici sans réversion, alors setDedicatedMsgSender a fonctionné
        assertTrue(true);
    }

    function test_sendToken_ETH() public {
        // Configurer le test : ajouter des ETH au contrat de paiement
        vm.deal(address(CFPayment), 5 ether);
        
        uint256 recipientBalanceBefore = recipient.balance;
        
        // Seul le CFContract est autorisé à appeler sendToken
        vm.startPrank(address(CFContract));
        vm.expectEmit(true, true, true, true);
        emit ChainflowPaymentSent(
            ZERO_ADDRESS,
            1 ether,
            address(CFPayment),
            recipient,
            block.timestamp
        );
        
        CFPayment.sendToken(ZERO_ADDRESS, 1 ether, payable(recipient));
        vm.stopPrank();
        
        // Vérifier que le destinataire a reçu les ETH
        assertEq(recipient.balance, recipientBalanceBefore + 1 ether);
    }

    function test_sendToken_ERC20() public {
        // Configurer le test : donner des tokens au contrat de paiement
        mockERC20.transfer(address(CFPayment), 1000 * 10**18);
        
        uint256 recipientBalanceBefore = mockERC20.balanceOf(recipient);
        
        // Seul le CFContract est autorisé à appeler sendToken
        vm.startPrank(address(CFContract));
        vm.expectEmit(true, true, true, true);
        emit ChainflowPaymentSent(
            address(mockERC20),
            100 * 10**18,
            address(CFPayment),
            recipient,
            block.timestamp
        );
        
        CFPayment.sendToken(address(mockERC20), 100 * 10**18, payable(recipient));
        vm.stopPrank();
        
        // Vérifier que le destinataire a reçu les tokens
        assertEq(mockERC20.balanceOf(recipient), recipientBalanceBefore + 100 * 10**18);
    }

    function test_sendToken_Unauthorized() public {
        // Essayer d'appeler sendToken depuis un compte non autorisé
        vm.startPrank(user1);
        vm.expectRevert("Only dedicated msg.sender");
        CFPayment.sendToken(ZERO_ADDRESS, 1 ether, payable(recipient));
        vm.stopPrank();
    }

    receive() external payable {}

    fallback() external payable {}
}
