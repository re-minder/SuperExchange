// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
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

contract SuperX is Simple777Recipient, SuperAppBase {
    using SafeMath for int96;
    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedTokenA; // accepted token A
    ISuperToken private _acceptedTokenB; // accepted token B
    address[] providers;
    int96 price = 0;
    int96 constant fullStreamPercentage = 10000;
    int96 constant providersFeePercentage = 30;
    int96 constant protocolsFeePercentage = 2;
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
            SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP;
        _host.registerApp(configWord);
    }
    /**************************************************************************
     * SatisfyFlows Logic
     *************************************************************************/
    function _strcmp(string memory str1, string memory str2) pure private returns (bool){
        return (keccak256(abi.encodePacked((str1))) == keccak256(abi.encodePacked((str2))));
    }
    // get minimum of flows from providers to the pool
    function _minOfABTokens(address LProvider) private view returns (int96 minFlow){
        (,int96 flowA,,) = _cfa.getFlow(_acceptedTokenA, LProvider, address(this));
        (,int96 flowB,,) = _cfa.getFlow(_acceptedTokenB, LProvider, address(this));
        if (flowA < flowB){
            minFlow = flowA;
        }else{
            minFlow = flowB;
        }
        return minFlow;
    }
    function _deleteProvider(address provider) private {
        for (uint i = 0; i < providers.length; i++){
            if (providers[i] == provider){
                providers[providers.length - 1] = providers[i];
                providers.pop();
            }
        }
    }
    // liquidity (only LPs will be streamers in this function)
    function _crupdeleteLiquidity(bytes memory _ctx, address streamer) private returns (bytes memory newCtx){
      (,int96 inFlowRateA,,) = _cfa.getFlow(_acceptedTokenA, streamer, address(this)); // inflow of token A from the user to the AMM
      (,int96 inFlowRateB,,) = _cfa.getFlow(_acceptedTokenB, streamer, address(this)); // inflow of token B from the user to the AMM
      (,int96 outFlowRateA,,) = _cfa.getFlow(_acceptedTokenA, address(this), streamer); // outflow of token A out of the AMM to the user
      (,int96 outFlowRateB,,) = _cfa.getFlow(_acceptedTokenB, address(this), streamer); // outflow of token B out of the AMM to the user
      //   if (inFlowRateA < 0 ) inFlowRateA = -inFlowRateA; // Fixes issue when inFlowRate is negative
      //   if (inFlowRateB < 0 ) inFlowRateB = -inFlowRateB; // Fixes issue when inFlowRate is negative
      newCtx = _ctx;
      if (inFlowRateA != outFlowRateA){
        if (inFlowRateA == int96(0)) {
            newCtx = _crupdeleteFlow(newCtx, _acceptedTokenA, streamer, inFlowRateA, "delete");
            if (!isInProvidersList(streamer)){
                _deleteProvider(streamer);
            }
        } else if (outFlowRateA != int96(0)){
            // @dev if there already exists an outflow, then update it.
            newCtx = _crupdeleteFlow(newCtx, _acceptedTokenA, streamer, inFlowRateA, "update");
        } else {
            // @dev If there is no existing outflow, then create new flow to equal inflow
            newCtx = _crupdeleteFlow(newCtx, _acceptedTokenA, streamer, inFlowRateA, "create");
        }
      }
      // if we do something with stream of token B, then we should use this condition structure
      if (inFlowRateB != outFlowRateB){ // check if something changed in balance of streams that would mean the user did something related to B tokens streams\
        if (inFlowRateB == int96(0)) {
            // @dev if inFlowRate is zero, delete outflow.
            newCtx = _crupdeleteFlow(newCtx, _acceptedTokenB, streamer, inFlowRateB, "delete");
            if (!isInProvidersList(streamer)){
                _deleteProvider(streamer);
            }
        } else if (outFlowRateB != int96(0)){
            // @dev if there already exists an outflow, then update it.
            newCtx = _crupdeleteFlow(newCtx, _acceptedTokenB, streamer, inFlowRateB, "update");
        } else {
            // @dev If there is no existing outflow, then create new flow to equal inflow
            newCtx = _crupdeleteFlow(newCtx, _acceptedTokenB, streamer, inFlowRateB, "create");
        }
      }
      return newCtx;
    }

    // function that allows for easily creating flows
    function _crupdeleteFlow(bytes memory _ctx, ISuperToken token, address receiver, int96 flowRate, string memory action) private returns (bytes memory newCtx){
        newCtx = _ctx;
        if (_strcmp(action, "create")){
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
        } else if (_strcmp(action, "update")){
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
        return newCtx;
    }
    // get amount of shares for each LP (their participation weight in the liquidity providing)
    function _getSharesForLProviders() view private returns (int96[] memory shares){
        for (uint i = 0; i < providers.length; i++){
            shares[i] = _minOfABTokens(providers[i]);
        }
        return shares;
    }
    // get amounts of tokens each LP should give
    function _getBoughtTokensPaidToProvidersFromAppForCurrentTrade(int96[] memory paidToAmounts)private view returns (int96[] memory amountsPaidFrom){
        for (uint i = 0; i < providers.length; i++){
            amountsPaidFrom[i] = paidToAmounts[i];
        }
        return amountsPaidFrom;
    }
    // amount that should be paid to each LProvider by the App based on their liquidity currently
    function _getSoldTokensPaidToProvidersFromAppForCurrentTrade(ISuperToken soldToken, int96 fullStream) private view returns (int96[] memory A_new, int96[] memory fees){

        int96 LPFee = providersFeePercentage*fullStream/fullStreamPercentage;
        int96 protocolFee = protocolsFeePercentage*fullStream/fullStreamPercentage;

        int96 fullStreamClean = fullStream - protocolFee - LPFee; // stripping the stream from all fees

        int96 B = 0; // full liquidity for bought token
        int96[] memory A_old = _getOldSoldTokensStreamedToProvidersFromApp(soldToken); // old amount of sold tokens distributed to LProviders
        int96[] memory shares = _getSharesForLProviders(); // share in the pool for each LProvider
        for (uint i = 0; i < providers.length; i++){
            B += shares[i];
        }
        for (uint i = 0; i < providers.length; i++){
            A_new[i] = shares[i]*fullStreamClean/B + A_old[i];
            fees[i] = shares[i]*LPFee/B;
        }
        return (A_new, fees);        
    }
    // get old amount of tokens paid to LProviders by the App (can be negative)
    function _getOldSoldTokensStreamedToProvidersFromApp(ISuperToken soldToken) view private returns (int96[] memory A_old){
        for (uint i = 0; i < providers.length; i++){
            (,A_old[i],,) = _cfa.getFlow(soldToken, address(this), providers[i]);
        }
        return A_old;
    }
    function _getOldBoughtTokensStreamedToProvidersFromApp(ISuperToken boughtToken) view private returns (int96[] memory B_old){
        for (uint i = 0; i < providers.length; i++){
            (,B_old[i],,) = _cfa.getFlow(boughtToken, address(this), providers[i]);
        }
        return B_old;
    }
    // update streams in accordance to the new Streams values
    function _updateStreamsToLPs(bytes memory _ctx, ISuperToken soldToken, int96[] memory newSoldTokenStreams, int96[] memory newBoughtTokenStreams) private returns (bytes memory newCtx) {

        ISuperToken boughtToken = _getAnotherToken(soldToken);
        newCtx = _ctx;
        for (uint i = 0; i < providers.length; i++){
            newCtx = _crupdeleteFlow(newCtx, soldToken, providers[i], newSoldTokenStreams[i], "update");
            newCtx = _crupdeleteFlow(newCtx, boughtToken, providers[i], newBoughtTokenStreams[i], "update");
        }
        return newCtx;
    }
    // needed only in the case of no liquidity in the pool, it just gives funds back to users
    function _streamBackToUser(bytes memory _ctx, address streamer, ISuperToken _superToken) private returns (bytes memory newCtx){

      newCtx = _ctx;
      (,int96 inFlow,,) = _cfa.getFlow(_superToken, streamer, address(this)); // inflow of token A from the user to the AMM
      (,int96 outFlow,,) = _cfa.getFlow(_superToken, address(this), streamer); // outflow of token A out of the AMM to the user
      //   if (inFlowRateA < 0 ) inFlowRateA = -inFlowRateA; // Fixes issue when inFlowRate is negative
      //   if (inFlowRateB < 0 ) inFlowRateB = -inFlowRateB; // Fixes issue when inFlowRate is negative
        if (inFlow == int96(0)) {
            newCtx = _crupdeleteFlow(newCtx, _superToken, streamer, inFlow, "delete");
            if (!isInProvidersList(streamer)){
                _deleteProvider(streamer);
            }
        } else if (outFlow != int96(0)){
            // @dev if there already exists an outflow, then update it.
            newCtx = _crupdeleteFlow(newCtx, _superToken, streamer, inFlow, "update");
        } else {
            // @dev If there is no existing outflow, then create new flow to equal inflow
            newCtx = _crupdeleteFlow(newCtx, _superToken, streamer, inFlow, "create");
        }
        return newCtx;
    }
    // LIQUIDITY SECTION
    function _createLiquidity(bytes memory _ctx, address streamer) private returns (bytes memory newCtx){
        
        newCtx = _ctx;
        int96 oldBoughtTokenStreamSum = 0;
        int96 oldSoldTokenStreamSum = 0;
        int96[] memory amountsSoldToken = _getOldSoldTokensStreamedToProvidersFromApp(_acceptedTokenA);
        int96[] memory amountsBoughtToken = _getOldBoughtTokensStreamedToProvidersFromApp(_acceptedTokenB);
        int96[] memory soldTokenInflows;
        int96[] memory boughtTokenInflows;
        int96 newSoldTokenAmount = 0;
        int96 newBoughtTokenAmount = 0;
        for (uint i = 0; i < providers.length; i++){
            oldBoughtTokenStreamSum += amountsSoldToken[i];
            oldSoldTokenStreamSum += amountsBoughtToken[i];
            (,soldTokenInflows[i],,) = _cfa.getFlow(_acceptedTokenA, streamer, address(this));
            (,boughtTokenInflows[i],,) = _cfa.getFlow(_acceptedTokenB, streamer, address(this));
            newSoldTokenAmount += soldTokenInflows[i];
            newBoughtTokenAmount += boughtTokenInflows[i];
        }
        int96[] memory newAmountsSoldToken;
        int96[] memory newAmountsBoughtToken;
        for (uint i = 0; i < providers.length; i++){
            newAmountsSoldToken[i] = oldSoldTokenStreamSum*soldTokenInflows[i]/newSoldTokenAmount;
            newAmountsBoughtToken[i] = oldBoughtTokenStreamSum*boughtTokenInflows[i]/newBoughtTokenAmount;
        }

        newCtx = _updateStreamsToLPs(newCtx, _acceptedTokenA, newAmountsSoldToken, newAmountsBoughtToken);

        return newCtx;

    }
    function _updateLiquidity(bytes memory _ctx, address streamer) private returns (bytes memory newCtx){
        newCtx = _ctx;

        int96 oldBoughtTokenStreamSum = 0;
        int96 oldSoldTokenStreamSum = 0;
        int96[] memory amountsSoldToken = _getOldSoldTokensStreamedToProvidersFromApp(_acceptedTokenA);
        int96[] memory amountsBoughtToken = _getOldBoughtTokensStreamedToProvidersFromApp(_acceptedTokenB);
        int96[] memory soldTokenInflows;
        int96[] memory boughtTokenInflows;
        int96 newSoldTokenAmount = 0;
        int96 newBoughtTokenAmount = 0;
        for (uint i = 0; i < providers.length - 1; i++){
            oldBoughtTokenStreamSum += amountsSoldToken[i];
            oldSoldTokenStreamSum += amountsBoughtToken[i];
            (,soldTokenInflows[i],,) = _cfa.getFlow(_acceptedTokenA, streamer, address(this));
            (,boughtTokenInflows[i],,) = _cfa.getFlow(_acceptedTokenB, streamer, address(this));
            newSoldTokenAmount += soldTokenInflows[i];
            newBoughtTokenAmount += boughtTokenInflows[i];
        }
        int96[] memory newAmountsSoldToken;
        int96[] memory newAmountsBoughtToken;
        for (uint i = 0; i < providers.length; i++){
            newAmountsSoldToken[i] = oldSoldTokenStreamSum*soldTokenInflows[i]/newSoldTokenAmount;
            newAmountsBoughtToken[i] = oldBoughtTokenStreamSum*boughtTokenInflows[i]/newBoughtTokenAmount;
        }

        newCtx = _updateStreamsToLPs(newCtx, _acceptedTokenA, newAmountsSoldToken, newAmountsBoughtToken);

        return newCtx;
    }
    function _deleteLiquidity(bytes memory _ctx, address streamer) private returns (bytes memory newCtx){

        newCtx = _ctx;
        
        int96 oldBoughtTokenStreamSum = 0;
        int96 oldSoldTokenStreamSum = 0;
        int96[] memory amountsSoldToken = _getOldSoldTokensStreamedToProvidersFromApp(_acceptedTokenA);
        int96[] memory amountsBoughtToken = _getOldBoughtTokensStreamedToProvidersFromApp(_acceptedTokenB);
        int96[] memory soldTokenInflows;
        int96[] memory boughtTokenInflows;
        int96 newSoldTokenAmount = 0;
        int96 newBoughtTokenAmount = 0;
        for (uint i = 0; i < providers.length - 1; i++){
            oldBoughtTokenStreamSum += amountsSoldToken[i];
            oldSoldTokenStreamSum += amountsBoughtToken[i];
            (,soldTokenInflows[i],,) = _cfa.getFlow(_acceptedTokenA, streamer, address(this));
            (,boughtTokenInflows[i],,) = _cfa.getFlow(_acceptedTokenB, streamer, address(this));
            newSoldTokenAmount += soldTokenInflows[i];
            newBoughtTokenAmount += boughtTokenInflows[i];
        }
        oldBoughtTokenStreamSum += amountsSoldToken[providers.length - 1];
        oldSoldTokenStreamSum += amountsBoughtToken[providers.length - 1];
        int96 streamerSoldFlow = soldTokenInflows[providers.length - 1];
        soldTokenInflows[providers.length - 1] = 0;
        boughtTokenInflows[providers.length - 1] = 0;
        int96[] memory newAmountsSoldToken;
        int96[] memory newAmountsBoughtToken;
        for (uint i = 0; i < providers.length; i++){
            newAmountsSoldToken[i] = oldSoldTokenStreamSum*soldTokenInflows[i]/newSoldTokenAmount;
            newAmountsBoughtToken[i] = oldBoughtTokenStreamSum*boughtTokenInflows[i]/newBoughtTokenAmount;
        }

        newCtx = _updateStreamsToLPs(newCtx, _acceptedTokenA, newAmountsSoldToken, newAmountsBoughtToken);

        // the liquidity provider downgrades to an ordinary user(
        ISuperToken soldToken = _acceptedTokenA;
        if (streamerSoldFlow == 0){
            soldToken = _acceptedTokenB;
        }
        _updateStream(_ctx, streamer, soldToken, 0);

        return newCtx;

    }
    function _getAnotherToken(ISuperToken _superToken1) private view returns (ISuperToken _superToken2){
        if (_superToken1 == _acceptedTokenA){
            return _acceptedTokenB;
        } else if (_superToken1 == _acceptedTokenB){
            return _acceptedTokenA;
        } else {
            revert("You use wrong token!");
        }
    }
    function _getRidOfStackTooDeepErrorCreate(bytes memory _ctx, ISuperToken _superToken) private returns (bytes memory newCtx){

        newCtx = _ctx;
        int96 anotherTokenInflowRate;
        address streamer = _host.decodeCtx(_ctx).msgSender;
        {
            ISuperToken anotherToken = _acceptedTokenA;
            if (_superToken == _acceptedTokenA){
                anotherToken = _acceptedTokenB;
            }
            (,anotherTokenInflowRate,,) = _cfa.getFlow(anotherToken, streamer, address(this)); // inflow of another token to the contract
        }
        if (anotherTokenInflowRate > 0){
            providers.push(streamer);
            newCtx = _createLiquidity(newCtx, streamer);
        }else{
            newCtx = _createStream(newCtx, streamer, _superToken);
        }
        return newCtx;

    }
    /**************************************************************************
     * SuperApp callbacks
     *************************************************************************/
    function _createStream(bytes memory _ctx, address streamer, ISuperToken soldToken) private returns (bytes memory newCtx){

        newCtx = _ctx;
        if (providers.length == 0) { // if there is no liquidity, just stream back to the streamer
            return _streamBackToUser(_ctx, streamer, soldToken); // don't wanna use _streamBackLiquidity here because it was not created for this purpose
        }
        
        int96 boughtTokenStreamToUser = 0;
        int96[] memory amountsPaidFrom;
        ISuperToken boughtToken = _getAnotherToken(soldToken);
        {
            int96[] memory newBoughtTokenStream;
            int96[] memory newSoldTokenStream;
            {
                int96[] memory fees;
                int96[] memory amountsPaidTo;
                (,int96 fullStream,,) = _cfa.getFlow(soldToken, streamer, address(this));
                int96[] memory oldAmountsPaidTo = _getOldSoldTokensStreamedToProvidersFromApp(soldToken);
                (amountsPaidTo, fees) = _getSoldTokensPaidToProvidersFromAppForCurrentTrade(soldToken, fullStream);
                for (uint i = 0; i < providers.length; i++){
                    newSoldTokenStream[i] = oldAmountsPaidTo[i] + amountsPaidTo[i] + fees[i];
                }
                amountsPaidFrom = _getBoughtTokensPaidToProvidersFromAppForCurrentTrade(amountsPaidTo);
            }

            {
                int96[] memory oldAmountsPaidFrom = _getOldBoughtTokensStreamedToProvidersFromApp(boughtToken);
                for (uint i = 0; i < providers.length; i++){
                    newBoughtTokenStream[i] = oldAmountsPaidFrom[i] - amountsPaidFrom[i];
                    boughtTokenStreamToUser += amountsPaidFrom[i];
                }
            }
            newCtx = _updateStreamsToLPs(newCtx, soldToken, newSoldTokenStream, newBoughtTokenStream);
        }
        newCtx = _crupdeleteFlow(newCtx, boughtToken, streamer, boughtTokenStreamToUser, "create");

        return newCtx;
        
    }
    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32,
        bytes calldata /*_agreementData*/,
        bytes calldata,
        bytes calldata _ctx
    )
        external override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        return _getRidOfStackTooDeepErrorCreate(_ctx, _superToken);
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
        returns (bytes memory /*cbdata*/)
    {
        (,int96 streamerInflow,,) = _cfa.getFlow(_superToken, _host.decodeCtx(_ctx).msgSender, address(this));
        return abi.encodePacked(streamerInflow, _superToken);
    }
    function _updateStream(bytes memory _ctx, address streamer, ISuperToken soldToken, int96 prevStream) private returns (bytes memory newCtx){

        newCtx = _ctx;
        if (providers.length == 0) { // if there is no liquidity, just stream back to the streamer
            _streamBackToUser(_ctx, streamer, soldToken); // don't wanna use _streamBackLiquidity here because it was not created for this purpose
        }
        
        int96 boughtTokenStreamToUser = prevStream;
        int96[] memory amountsPaidFrom;
        ISuperToken boughtToken = _getAnotherToken(soldToken);
        {
            int96[] memory newBoughtTokenStream;
            int96[] memory newSoldTokenStream;
            {
                int96[] memory fees;
                int96[] memory amountsPaidTo;
                (,int96 fullStream,,) = _cfa.getFlow(soldToken, streamer, address(this));
                int96[] memory oldAmountsPaidTo = _getOldSoldTokensStreamedToProvidersFromApp(soldToken);
                (amountsPaidTo, fees) = _getSoldTokensPaidToProvidersFromAppForCurrentTrade(soldToken, fullStream - prevStream);
                for (uint i = 0; i < providers.length; i++){
                    newSoldTokenStream[i] = oldAmountsPaidTo[i] + amountsPaidTo[i] + fees[i];
                }
                amountsPaidFrom = _getBoughtTokensPaidToProvidersFromAppForCurrentTrade(amountsPaidTo);
            }

            {
                int96[] memory oldAmountsPaidFrom = _getOldBoughtTokensStreamedToProvidersFromApp(boughtToken);
                for (uint i = 0; i < providers.length; i++){
                    newBoughtTokenStream[i] = oldAmountsPaidFrom[i] - amountsPaidFrom[i];
                    boughtTokenStreamToUser += amountsPaidFrom[i];
                }
            }
            newCtx = _updateStreamsToLPs(newCtx, soldToken, newSoldTokenStream, newBoughtTokenStream);
        }
        newCtx = _crupdeleteFlow(newCtx, boughtToken, streamer, boughtTokenStreamToUser, "update");

        return newCtx;

    }
    function _getRidOfStackTooDeepErrorUpdate(bytes memory _ctx, bytes calldata _cbdata) private returns (bytes memory newCtx){

        newCtx = _ctx;
        address streamer = _host.decodeCtx(newCtx).msgSender;
        (int96 prevStream, ISuperToken _superToken) = abi.decode(_cbdata, (int96, ISuperToken));
        int96 anotherTokenInflowRate;
        {
            ISuperToken anotherToken = _acceptedTokenA;
            if (_superToken == _acceptedTokenA){
                anotherToken = _acceptedTokenB;
            }
            (,anotherTokenInflowRate,,) = _cfa.getFlow(anotherToken, streamer, address(this)); // inflow of another token to the contract
        }
        if (anotherTokenInflowRate > 0){
            providers.push(streamer);
            newCtx = _updateLiquidity(newCtx, streamer);
        }else{
            newCtx = _updateStream(newCtx, streamer, _superToken, prevStream);
        }

        return newCtx;

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
        return _getRidOfStackTooDeepErrorUpdate(_ctx, _cbdata);
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
        (,int96 streamerInflow,,) = _cfa.getFlow(_superToken, streamer, address(this));
        return abi.encodePacked(streamerInflow, streamer, _superToken);
    }
    function _deleteStream(bytes memory _ctx, address streamer, ISuperToken soldToken, int96 prevStream) private returns (bytes memory newCtx){

        if (providers.length == 0) { // if there is no liquidity
            return _ctx; // just close the stream and that's all
        }
        
        newCtx = _ctx;
        int96 boughtTokenStreamToUser = prevStream;
        int96[] memory amountsPaidFrom;
        ISuperToken boughtToken = _getAnotherToken(soldToken);
        {
            int96[] memory newBoughtTokenStream;
            int96[] memory newSoldTokenStream;
            {
                int96[] memory fees;
                int96[] memory amountsPaidTo;
                int96 fullStream = 0;
                int96[] memory oldAmountsPaidTo = _getOldSoldTokensStreamedToProvidersFromApp(soldToken);
                (amountsPaidTo, fees) = _getSoldTokensPaidToProvidersFromAppForCurrentTrade(soldToken, fullStream - prevStream);
                for (uint i = 0; i < providers.length; i++){
                    newSoldTokenStream[i] = oldAmountsPaidTo[i] + amountsPaidTo[i] + fees[i];
                }
                amountsPaidFrom = _getBoughtTokensPaidToProvidersFromAppForCurrentTrade(amountsPaidTo);
            }

            {
                int96[] memory oldAmountsPaidFrom = _getOldBoughtTokensStreamedToProvidersFromApp(boughtToken);
                for (uint i = 0; i < providers.length; i++){
                    newBoughtTokenStream[i] = oldAmountsPaidFrom[i] - amountsPaidFrom[i];
                    boughtTokenStreamToUser += amountsPaidFrom[i];
                }
            }
            newCtx = _updateStreamsToLPs(newCtx, soldToken, newSoldTokenStream, newBoughtTokenStream);
        }
        newCtx = _crupdeleteFlow(newCtx, boughtToken, streamer, boughtTokenStreamToUser, "update");

        return newCtx;

    }
    function _getRidOfStackTooDeepErrorDelete(bytes memory _ctx, bytes calldata _cbdata) private returns (bytes memory newCtx){

        newCtx = _ctx;
        (int96 prevStream, address streamer, ISuperToken _superToken) = abi.decode(_cbdata, (int96, address, ISuperToken));
        int96 anotherTokenInflowRate;
        {
            ISuperToken anotherToken = _acceptedTokenA;
            if (_superToken == _acceptedTokenA){
                anotherToken = _acceptedTokenB;
            }
            (,anotherTokenInflowRate,,) = _cfa.getFlow(anotherToken, streamer, address(this)); // inflow of another token to the contract
        }
        if (anotherTokenInflowRate > 0){
            newCtx = _deleteLiquidity(newCtx, streamer);
            _deleteProvider(streamer);
        }else{
            newCtx = _deleteStream(newCtx, streamer, _superToken, prevStream);
        }
        return newCtx;

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
        return _getRidOfStackTooDeepErrorDelete(_ctx, _cbdata);
    }
    function getNetFlowA() public view returns (int96) {
       return _cfa.getNetFlow(_acceptedTokenA, address(this));
    }
    function getNetFlowB() public view returns (int96) {
       return _cfa.getNetFlow(_acceptedTokenB, address(this));
    }
    function abs(int96 x) private pure returns (int96) {
        return x >= 0 ? x : -x;
    }
    // x*y = k, (x + a*(y + b) = k,
    // x*y = (x + a)*(y + b),
    // (x + a) = x*y/(y + b), y + b is known if the user trades second token,
    // (y + b) = x*y/(x + a), x + a is known if the user trades first token

    function _isAllowedToken(ISuperToken superToken) private view returns (bool) {
        return address(superToken) == address(_acceptedTokenA) || address(superToken) == address(_acceptedTokenB);
    }
    function _isCFAv1(address agreementClass) private view returns (bool) {
        return ISuperAgreement(agreementClass).agreementType()
            == keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");
    }
    modifier onlyHost() {
        require(msg.sender == address(_host), "SatisfyFlows: support only one host");
        _;
    }
    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(_isAllowedToken(superToken), "SatisfyFlows: not accepted token");
        require(_isCFAv1(agreementClass), "SatisfyFlows: only CFAv1 supported");
        _;
    }
    function isInProvidersList(address user) public view returns (bool){
        for (uint i = 0; i < providers.length; i++){
            if (providers[i] == user){
                return true;
            }
        }
        return false;
    }
}