// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TwoFactorAuth {
    struct User {
        string username;
        address publicKey;
        bytes32 otpSeed;
        uint256 lastOTP;
        uint256 lastLoginTime;
    }

    mapping(address => User) public users;
    
    event UserRegistered(address user, string username);
    event Authenticated(address user, string username);

    uint256 constant TIME_WINDOW = 60;  // OTP valid for 30 seconds
    uint256 constant OTP_LENGTH = 6;    // OTP length

    modifier onlyRegistered() {
        require(users[msg.sender].publicKey != address(0), "User not registered");
        _;
    }

    // Register a new user
    function registerUser(string memory _username, address _publicKey, bytes32 _otpSeed) public {
        require(users[_publicKey].publicKey == address(0), "User already registered");
        
        users[_publicKey] = User({
            username: _username,
            publicKey: _publicKey,
            otpSeed: _otpSeed,
            lastOTP: 0,
            lastLoginTime: 0
        });
        
        emit UserRegistered(_publicKey, _username);
    }

    function convert(uint256 n) public pure returns (bytes32) {
    return bytes32(n);
}

    // Generate OTP using a hash-based method with time factor
    function generateOTP(address _user) public view onlyRegistered returns (uint256) {
        User storage user = users[_user];
        uint256 timeFactor = block.timestamp / TIME_WINDOW;
        bytes32 otpHash = keccak256(abi.encodePacked(user.otpSeed, timeFactor));
        uint256 otp = uint256(otpHash) % (10 ** OTP_LENGTH);  // Restrict to 6 digits
        return otp;
    }

    // Authenticate a user with OTP
    function authenticate(address _user, uint256 _otp) public onlyRegistered returns (bool) {
        User storage user = users[_user];
        require(block.timestamp - user.lastLoginTime > TIME_WINDOW, "OTP replay attack detected");
        
        uint256 currentOTP = generateOTP(_user);
        require(currentOTP == _otp, "Invalid OTP");

        user.lastOTP = _otp;
        user.lastLoginTime = block.timestamp;

        emit Authenticated(_user, user.username);
        return true;
    }
}
