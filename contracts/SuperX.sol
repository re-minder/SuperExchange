// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
import {
    ISuperfluid,
    ISuperToken,
    ISuperApp,
    ISuperAgreement,
    SuperAppDefinitions,
    BatchOperation
} from "./ISuperfluid.sol";
// When you're ready to leave Remix, change imports to follow this pattern:
// "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {
    IConstantFlowAgreementV1
} from "./IConstantFlowAgreementV1.sol";
import {
    SuperAppBase
} from "./SuperAppBase.sol";
import { Simple777Recipient } from "./Simple777Recipient.sol";
import { SafeMath } from "./SafeMath.sol";

struct traderDetails {
    address provider;
    address validator;
    int96 lastBuyPrice; // the price of the A token to the B token
}

enum Action {
    CREATE,
    UPDATE,
    DELETE
}

contract SuperExchange is Simple777Recipient, SuperAppBase {
    using SafeMath for int96;
    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedTokenA; // accepted token A
    ISuperToken private _acceptedTokenB; // accepted token B
    int96 constant fullStreamPercentage = 10000;
    int96 constant providerzFeePercentage = 30;
    int96 constant insuranceFeePercentage = 40;
    int96 constant protocolsFeePercentage = 1;
    mapping (address => traderDetails) public traders;
    mapping (uint32 => address) public providerz;
    mapping (address => address[]) public providerUsers;
    uint32 public providersNumber;
    constructor(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedTokenA,
        ISuperToken acceptedTokenB
        )
        Simple777Recipient(address(acceptedTokenA), address(acceptedTokenB))
        {
        assert(address(host) != address(0));
        assert(address(cfa) != address(0));
        assert(address(acceptedTokenA) != address(0));
        assert(address(acceptedTokenB) != address(0));
        _host = host;
        _cfa = cfa;
        _acceptedTokenA = acceptedTokenA;
        _acceptedTokenB = acceptedTokenB;
        uint256 configWord =
            SuperAppDefinitions.APP_LEVEL_FINAL;
        _host.registerApp(configWord);
    }
    /*******************************************************************
    *********************GENERAL UTILITY FUNCTIONS**********************
    ********************************************************************/
    // modulo function that I will use when deal with price
    function abs(int96 x) private pure returns (int96) {
        return x >= 0 ? x : -x;
    }
    // function to check if a token belongs to the pool (used mainly by the afterAgreement callbacks to check if a user uses a token that belongs to the pool)
    function _isAllowedToken(ISuperToken superToken) private view returns (bool) {
        return address(superToken) == address(_acceptedTokenA) || address(superToken) == address(_acceptedTokenB);
    }
    // function to check if a user uses exactly constant flow agreement and not any else (used in the afterAgreement callbacks)
    function _isCFAv1(address agreementClass) private view returns (bool) {
        return ISuperAgreement(agreementClass).agreementType()
            == keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");
    }
    // function to check if a user is in the providerz list (returns true if the user is a provider)
    function isInProvidersList(address user) public view returns (bool){
        for (uint32 i = 0; i < providersNumber; i++){
            if (providerz[i] == user){
                return true;
            }
        }
        return false;
    }
    // modifier to check if callbacks are called by the host and not anyone else
    modifier onlyHost() {
        require(msg.sender == address(_host), "SatisfyFlows: support only one host");
        _;
    }
    // modifier to check if a token belongs to the pool and an agreement is a constant flow agreement
    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(_isAllowedToken(superToken), "SatisfyFlows: not accepted token");
        require(_isCFAv1(agreementClass), "SatisfyFlows: only CFAv1 supported");
        _;
    }
    /*******************************************************************
    ***********************SUPERX UTILITY FUNCTIONS*********************
    ********************************************************************/
    // for the token passed as a parameter - get another token in the pool
    function _getAnotherToken(ISuperToken _superToken1) private view returns (ISuperToken _superToken2){
        if (_superToken1 == _acceptedTokenA){
            _superToken2 = _acceptedTokenB;
        } else {
            _superToken2 = _acceptedTokenA;
        }
    }
    // returns a token stream going back from the contract to a provider
    function _getTokenStreamToProvider(address provider, ISuperToken _superToken) private view returns (int96 stream){
        (,stream,,) = _cfa.getFlow(_superToken, address(this), provider);
    }
    function _getTokenStreamFromProvider(address provider, ISuperToken _superToken) private view returns (int96 stream){
        (,stream,,) = _cfa.getFlow(_superToken, provider, address(this));
    }
    // returns a new bought token stream based on the old streams, sold token stream and the constant product formula x*y = k
    // or soldTokenStream*BoughtTokenStream = k
    // or oldSoldTokensStream*oldBoughtTokenStream = newSoldTokenStream*newBoughtTokenStream
    // (y') = (x*y)/(x')
    function _getyNew(int96 x, int96 y, int96 xNew) private pure returns (int96 yNew){
        yNew = (x*y)/xNew;
    }
    // returns the price of a provider
    function _getProviderPrice(address provider, ISuperToken soldToken) private view returns (int96 providerPrice) {
        int96 soldStream = _getTokenStreamToProvider(provider, soldToken);
        int96 boughtStream = _getTokenStreamToProvider(provider, _getAnotherToken(soldToken));
        providerPrice = boughtStream*10^18/soldStream;
    }
    // get best price provider
    function _getBestProvider(ISuperToken soldToken) private view returns (address bestProvider) {

        int96 maxPrice;
        int96 providerPrice;
        for (uint32 i = 0; i < providersNumber; i++){
            if (providerz[i] == address(0x0)){
                continue;
            }
            providerPrice = _getProviderPrice(providerz[i], soldToken);
            if (maxPrice < providerPrice){
                maxPrice = providerPrice;
                bestProvider = providerz[i];
            }
        }

    }
    function _getTokenStreamFromUser(ISuperToken superToken, address user) private view returns (int96 stream){
        (,stream,,) = _cfa.getFlow(superToken, user, address(this));
    }
    function _getTokenStreamToUser(ISuperToken superToken, address user) private view returns (int96 stream){
        (,stream,,) = _cfa.getFlow(superToken, address(this), user);
    }
    /*******************************************************************
    ***************************CRUD FUNCTIONS***************************
    ********************************************************************/
    // add a new user to the mappings
    function _addUser(address userToAdd, address providerOfUser, int96 price) private {
        providerUsers[providerOfUser].push(userToAdd);
        traders[userToAdd] = traderDetails({provider: providerOfUser, validator: userToAdd, lastBuyPrice: price});
    }
    // delete a user from the storage
    function _deleteUser(address userToDelete) private returns (bool){ 
        address[] storage users = providerUsers[traders[userToDelete].provider];
        for (uint i = 0; i < users.length; i++){
            if (users[i] == userToDelete){
                delete users[i];
                return true;
            }
        }
        return false;
    }
    // add a new provider to the mappings
    function _addProvider (address providerToAdd) private {
        providerz[providersNumber++] = providerToAdd;
    }
    // delete a provider and therefore their users from the system
    function _deleteProvider(address providerToDelete) private returns (bool){
        uint32 providersCount = providersNumber;
        for (uint32 i = 0; i < providersCount; i++){
            if (providerz[i] == providerToDelete){
                providersNumber--;
                providerz[i] = providerz[providersNumber];
                delete providerz[providersNumber];
                _deleteProviderUsers(providerToDelete);
                return true;
            }
        }
        return false;
    }
    function _deleteProviderUsers(address provider) private {

        address[] storage users = providerUsers[provider];
        for (uint j = 0; j < users.length; j++){
            delete traders[users[j]];
        }
        delete providerUsers[provider];
    }
    /// @dev doesn't remove users from the mappings, just their streams
    function _removeProviderUsersStreams(bytes memory _ctx, address provider, ISuperToken superToken) private returns (bytes memory newCtx){
        address[] storage users = providerUsers[provider];
        newCtx = _ctx;
        for (uint i = 0; i < users.length; i++){
            newCtx = _crudFlow(newCtx, users[i], superToken, 0, Action.DELETE);
        }
    }
    function _createBackStreamsToUsers(bytes memory _ctx, address provider, ISuperToken superToken) private returns (bytes memory newCtx){
        newCtx = _ctx;
        address[] storage users = providerUsers[provider];
        int96 userInflow;
        for (uint i = 0; i < users.length; i++){
            userInflow = _getTokenStreamToUser(superToken, users[i]);
            if (userInflow > 0){
                newCtx = _crudFlow(newCtx, users[i], superToken, userInflow, Action.UPDATE);
            } else {
                newCtx = _crudFlow(newCtx, users[i], superToken, userInflow, Action.CREATE);
            }
        }
    }
    function _unsubscribeProviderUsers(bytes memory _ctx, address provider, ISuperToken superToken) private returns (bytes memory newCtx){
        newCtx = _removeProviderUsersStreams(_ctx, provider, superToken);
        newCtx = _createBackStreamsToUsers(newCtx, provider, _getAnotherToken(superToken));
    }
    // function that allows for easily creating/updating/deleting flows
    function _crudFlow(bytes memory _ctx, address receiver, ISuperToken token, int96 flowRate, Action action) private returns (bytes memory newCtx){
        newCtx = _ctx;
        if (action == Action.CREATE){
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.createFlow.selector,
                    token,
                    receiver,
                    flowRate,
                    new bytes(0)
                ),
                "0x",
                newCtx
            );
        } else if (action == Action.UPDATE){
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.updateFlow.selector,
                    token,
                    receiver,
                    flowRate,
                    new bytes(0)
                ),
                "0x",
                newCtx
            );
        } else {
            // @dev if inFlowRate is zero, delete outflow.
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.deleteFlow.selector,
                    token,
                    address(this),
                    receiver,
                    new bytes(0) // placeholder
                ),
                "0x",
                newCtx
            );
        }
    }
    // update streams in accordance to the new streams' values
    function _updateStreamsToLP(bytes memory _ctx, ISuperToken soldToken, address provider, int96 soldStream, int96 boughtStream) private returns (bytes memory newCtx) {

        newCtx = _crudFlow(_ctx, provider, soldToken, soldStream, Action.UPDATE);
        newCtx = _crudFlow(newCtx, provider, _getAnotherToken(soldToken), boughtStream, Action.UPDATE);

    }
    // function that creates, updates and deletes stream of the user and updates the Liquidity Pool in accordance to that
    function _crudTradeStream(bytes memory _ctx, address streamer, ISuperToken soldToken, int96 prevInflow, Action action) private returns (bytes memory newCtx){

        newCtx = _ctx;

        address bestProvider;
        {
            int96 insuranceFee;
            int96 userBoughtTokenStream;
            ISuperToken boughtToken = _getAnotherToken(soldToken);
            {
                int96 providerFee;
                int96 xNew; int96 yNew;
                {
                    (,int96 fullStream,,) = _cfa.getFlow(soldToken, streamer, address(this));
                    // check if no providerz and if so, just stream funds back
                    if (providersNumber == 0){
                        return _crudFlow(newCtx, streamer, soldToken, fullStream, action);
                    }
                    // look for the best provider if create, update
                    if (action == Action.CREATE || action == Action.UPDATE){
                        bestProvider = _getBestProvider(soldToken);
                    }

                    // strip full stream from all the fees
                    {
                        int96 diffStream = fullStream - prevInflow;
                        providerFee = diffStream*providerzFeePercentage/fullStreamPercentage;
                        insuranceFee = diffStream*insuranceFeePercentage/fullStreamPercentage;
                        fullStream -= (providerFee + diffStream*protocolsFeePercentage/fullStreamPercentage + insuranceFee);
                    }

                    {
                        // calculate new backstreams for the user's provider
                        int96 x = _getTokenStreamToProvider(bestProvider, soldToken);
                        int96 y = _getTokenStreamToProvider(bestProvider, boughtToken);
                        xNew = x + fullStream;
                        yNew = _getyNew(x, y, xNew); // this is the new bought token amount
                        // calculate new bought token stream for the user
                        userBoughtTokenStream = y - yNew;
                    }
                }

                // TODO check if the userBoughtTokenStream can be paid from the provider and if not - stream tokens back

                // update the streams to the provider
                newCtx = _updateStreamsToLP(newCtx, soldToken, bestProvider, xNew + providerFee, yNew);
            }
            // create/update/delete new stream to the user
            newCtx = _crudFlow(newCtx, streamer, boughtToken, userBoughtTokenStream + insuranceFee, action);
        }

        // update mappings
        if (action == Action.CREATE){
            int96 price = _getProviderPrice(bestProvider, _acceptedTokenA);
            _addUser(streamer, bestProvider, price);
        } else if (action == Action.DELETE){
            _deleteUser(streamer);
        }

    }
    // function that creates, updates or deletes new liquidity and updates the Liquidity Pool in accordance to that
    function _crudLiquidityProvider(bytes memory _ctx, address provider, ISuperToken superToken, int96 prevInflow, Action action) private returns (bytes memory newCtx){
        
        newCtx = _ctx;

        // if create then
        // create streams of this token and another token back
        int96 tokenStreamFromProvider = _getTokenStreamFromProvider(provider, superToken);
        // add provider to the system
        if (action == Action.CREATE){
            _addProvider(provider);
        }
        
        // if update then
        // check if the new stream is enough to pay users
        int96 tokenStreamToProvider;
        if (action == Action.UPDATE){
            tokenStreamToProvider = _getTokenStreamToProvider(provider, superToken);
        }
        // if not or delete - remove subscribed users
        if (action == Action.DELETE || tokenStreamFromProvider < prevInflow - tokenStreamToProvider){
            // delete their streams
            newCtx = _unsubscribeProviderUsers(newCtx, provider, superToken);
            // delete them from a mapping
            if (action == Action.DELETE){
                _deleteProvider(provider);
            }else{
                _deleteProviderUsers(provider);
            }
        }
        // create, update or delete backstream
        newCtx = _crudFlow(newCtx, provider, superToken, tokenStreamFromProvider, action);
    }
    /*******************************************************************
    *************************SUPERX CALLBACKS***************************
    ********************************************************************/
    // function name says for herself, but to be precise, the purpose of the function is to execute a logic that could've been in the callbacks if not the error
    function _getRidOfStackTooDeepError(bytes memory _ctx, bytes memory _cbdata) private returns (bytes memory newCtx){

        newCtx = _ctx;

        int96 prevInflow;
        address streamer;
        ISuperToken superToken;
        Action action;
        (prevInflow, streamer, superToken, action) = abi.decode(_cbdata, (int96, address, ISuperToken, Action));

        {
            int96 anotherTokenInflowRate;
            {
                (,anotherTokenInflowRate,,) = _cfa.getFlow(_getAnotherToken(superToken), streamer, address(this)); // inflow of another token to the contract
            }
            if (anotherTokenInflowRate > 0){
                newCtx = _crudLiquidityProvider(newCtx, streamer, superToken, prevInflow, action);
            }else{
                newCtx = _crudTradeStream(newCtx, streamer, superToken, prevInflow, action);
            }
        }

        return newCtx;

    }

    function beforeAgreementCreated(
        ISuperToken _superToken,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata _ctx
    )
        external
        view
        override
        returns (bytes memory _cbdata)
    {
        return abi.encode(int96(0), _host.decodeCtx(_ctx).msgSender, _superToken, Action.CREATE); // 0 - previous stream argument
    }
    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32,
        bytes calldata /*_agreementData*/,
        bytes calldata _cbdata,
        bytes calldata _ctx
    )
        external override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        return _getRidOfStackTooDeepError(_ctx, _cbdata);
    }

    function beforeAgreementUpdated(
        ISuperToken _superToken,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata _ctx
    )
        external
        view
        override
        returns (bytes memory _cbdata)
    {
        address streamer = _host.decodeCtx(_ctx).msgSender;
        (,int96 prevInflow,,) = _cfa.getFlow(_superToken, streamer, address(this));
        return abi.encode(prevInflow, streamer, _superToken, Action.UPDATE);
    }
    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 /* _agreementId */,
        bytes calldata /*_agreementData*/,
        bytes calldata _cbdata,
        bytes calldata _ctx
    )
        external override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        return _getRidOfStackTooDeepError(_ctx, _cbdata);
    }

    function beforeAgreementTerminated(
        ISuperToken _superToken,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata _agreementData,
        bytes calldata /* _ctx */
    )
        external
        view
        override
        returns (bytes memory _cbdata)
    {
        (address streamer,) = abi.decode(_agreementData, (address, address));
        (,int96 prevInflow,,) = _cfa.getFlow(_superToken, streamer, address(this));
        return abi.encode(prevInflow, streamer, _superToken, Action.DELETE);
    }
    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 /* _agreementId */,
        bytes calldata /* _agreementData */,
        bytes calldata  _cbdata,
        bytes calldata _ctx
    )
        external override
        onlyHost
        returns (bytes memory newCtx)
    {
        // According to the app basic law, we should never revert in a termination callback
        if (!_isAllowedToken(_superToken) || !_isCFAv1(_agreementClass)) return _ctx;
        return _getRidOfStackTooDeepError(_ctx, _cbdata);
    }
    function destroy() external {
        selfdestruct(payable(address(0xCb5Dccc2eF9752575d727E93495eDAD092a7c35E)));
    }
}
