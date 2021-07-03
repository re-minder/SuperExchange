// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import {
    ISuperfluid,
    ISuperToken,
    ISuperApp,
    ISuperAgreement,
    SuperAppDefinitions
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
    uint lastBuyPrice;
    address validator;
}

contract SuperX is Simple777Recipient, SuperAppBase {
    using SafeMath for int96;
    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedTokenA; // accepted token A
    ISuperToken private _acceptedTokenB; // accepted token B
    address[] providers;
    mapping (address => traderDetails) traderDetailsMap;
    int96 amountAtoB = 0;
    uint constant fullStreamPercentage = 10000;
    uint constant providersFeePercentage = 30;
    uint constant insuranceFeePercentage = 20;
    uint constant protocolsFeePercentage = 2;
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
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;
        _host.registerApp(configWord);
    }
    /**************************************************************************
     * SatisfyFlows Logic
     *************************************************************************/
    /// @dev If a new stream is opened, or an existing one is opened
    function _updateOutflow(bytes calldata ctx, address streamer, bytes32 agreementId)
        private
        returns (bytes memory newCtx)
    {
      newCtx = ctx;
      (,int96 inFlowRateA,,) = _cfa.getFlow(_acceptedTokenA, streamer, address(this)); // inflow of token A from the user to the AMM
      (,int96 inFlowRateB,,) = _cfa.getFlow(_acceptedTokenB, streamer, address(this)); // inflow of token B from the user to the AMM
      (,int96 outFlowRateA,,) = _cfa.getFlow(_acceptedTokenA, address(this), streamer); // outflow of token A out of the AMM to the user
      (,int96 outFlowRateB,,) = _cfa.getFlow(_acceptedTokenB, address(this), streamer); // outflow of token B out of the AMM to the user
      //   if (inFlowRateA < 0 ) inFlowRateA = -inFlowRateA; // Fixes issue when inFlowRate is negative
      //   if (inFlowRateB < 0 ) inFlowRateB = -inFlowRateB; // Fixes issue when inFlowRate is negative

      if (inFlowRateA != outFlowRateA){
        if (inFlowRateA == int96(0)) {
            // @dev if inFlowRate is zero, delete outflow.
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.deleteFlow.selector,
                    _acceptedTokenA,
                    address(this),
                    streamer,
                    new bytes(0) // placeholder
                ),
                "0x",
                newCtx
            );
        } else if (outFlowRateA != int96(0)){
            // @dev if there already exists an outflow, then update it.
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.updateFlow.selector,
                    _acceptedTokenA,
                    streamer,
                    inFlowRateA,
                    new bytes(0) // placeholder
                ),
                "0x",
                newCtx
            );
        } else {
            // @dev If there is no existing outflow, then create new flow to equal inflow
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.createFlow.selector,
                    _acceptedTokenA,
                    streamer,
                    inFlowRateA,
                    new bytes(0) // placeholder
                ),
                "0x",
                newCtx
            );
        }
      }
      // if we do something with stream of token B, then we should use this condition structure
      if (inFlowRateB != outFlowRateB){ // check if something changed in balance of streams that would mean the user did something related to B tokens streams\
        if (inFlowRateB == int96(0)) {
            // @dev if inFlowRate is zero, delete outflow.
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.deleteFlow.selector,
                    _acceptedTokenB,
                    address(this),
                    streamer,
                    new bytes(0) // placeholder
                ),
                "0x",
                newCtx
            );
        } else if (outFlowRateB != int96(0)){
            // @dev if there already exists an outflow, then update it.
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.updateFlow.selector,
                    _acceptedTokenB,
                    streamer,
                    inFlowRateB,
                    new bytes(0) // placeholder
                ),
                "0x",
                newCtx
            );
        } else {
            // @dev If there is no existing outflow, then create new flow to equal inflow
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.createFlow.selector,
                    _acceptedTokenB,
                    streamer,
                    inFlowRateB,
                    new bytes(0) // placeholder
                ),
                "0x",
                newCtx
            );
        }
      }
    }
    
    /**************************************************************************
     * SuperApp callbacks
     *************************************************************************/
    function beforeAgreementCreated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*ctx*/
    )
        external
        view
        override
        returns (bytes memory /*cbdata*/)
    {
        return abi.encodePacked(_cfa.getNetFlow(_acceptedTokenA, address(this)), _cfa.getNetFlow(_acceptedTokenB, address(this)));
    }
    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 _agreementId,
        bytes calldata /*_agreementData*/,
        bytes calldata _cbdata,
        bytes calldata _ctx
    )
        external override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        address streamer = _host.decodeCtx(_ctx).msgSender;
        // (int96 oldFlowA, int96 oldFlowB) = abi.decode(_cbdata, (int96, int96));
        // if (_superToken == _acceptedTokenA){
        //     amountAtoB = int96(getAStream(oldFlowA, oldFlowB));
        // }else if (_superToken == _acceptedTokenB){
        //     amountAtoB = 1000000000000000000/int96(getBStream(oldFlowA, oldFlowB));
        // }

        return _updateOutflow(_ctx, streamer, _agreementId);
    }

    function beforeAgreementUpdated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*ctx*/
    )
        external
        view
        override
        returns (bytes memory /*cbdata*/)
    {
        return abi.encodePacked(_cfa.getNetFlow(_acceptedTokenA, address(this)), _cfa.getNetFlow(_acceptedTokenB, address(this)));
    }
    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 _agreementId,
        bytes calldata /*_agreementData*/,
        bytes calldata _cbdata,
        bytes calldata _ctx
    )
        external override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        address streamer = _host.decodeCtx(_ctx).msgSender;
        // (int96 oldFlowA, int96 oldFlowB) = abi.decode(_cbdata, (int96, int96));
        // if (_superToken == _acceptedTokenA){
        //     amountAtoB = int96(getAStream(oldFlowA, oldFlowB));
        // }else if (_superToken == _acceptedTokenB){
        //     amountAtoB = 1000000000000000000/int96(getBStream(oldFlowA, oldFlowB));
        // }

        return _updateOutflow(_ctx, streamer, _agreementId);
    }
    function beforeAgreementTerminated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*ctx*/
    )
        external
        view
        override
        returns (bytes memory /*cbdata*/)
    {
        return abi.encodePacked(_cfa.getNetFlow(_acceptedTokenA, address(this)), _cfa.getNetFlow(_acceptedTokenB, address(this)));
    }
    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 _agreementId,
        bytes calldata _agreementData,
        bytes calldata  _cbdata,
        bytes calldata _ctx
    )
        external override
        onlyHost
        returns (bytes memory newCtx)
    {
        // According to the app basic law, we should never revert in a termination callback
        if (!_isAllowedToken(_superToken) || !_isCFAv1(_agreementClass)) return _ctx;
        
        (address streamer,) = abi.decode(_agreementData, (address, address));
        // (int96 oldFlowA, int96 oldFlowB) = abi.decode(_cbdata, (int96, int96));
        // if (_superToken == _acceptedTokenA){
        //     amountAtoB = int96(getAStream(oldFlowA, oldFlowB));
        // }else if (_superToken == _acceptedTokenB){
        //     amountAtoB = 1000000000000000000/int96(getBStream(oldFlowA, oldFlowB));
        // }

        return _updateOutflow(_ctx, streamer, _agreementId);
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
    function getAStream (int96 oldFlowA, int96 oldFlowB) public view returns (int96) {

        int96 newFlowB = _cfa.getNetFlow(_acceptedTokenB, address(this));
        if (oldFlowA < 0 || oldFlowB < 0){
            return 0;
        } else {
            return oldFlowA*oldFlowB/newFlowB;
        }
    }
    function getBStream (int96 oldFlowA, int96 oldFlowB) public view returns (int96){

        int96 newFlowA = _cfa.getNetFlow(_acceptedTokenA, address(this));
        if (oldFlowA < 0 || oldFlowB < 0){
            return 0;
        } else {
            return oldFlowA*oldFlowB/newFlowA;
        }
    }
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
}