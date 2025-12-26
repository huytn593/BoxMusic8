using backend.Interfaces;
using backend.Models;
using backend.Utils.Securities;
using MongoDB.Driver;
using System.IdentityModel.Tokens.Jwt;
using System.Reflection;
using StackExchange.Redis;

namespace backend.Services
{
    public class UsersService : IUsersService
    {
        private readonly IUserRepository _usersRepository;
        private readonly IJWTService _jwtService;
        private readonly ITokenBlacklistService _tokenBlacklistService;
        private readonly IConnectionMultiplexer _redis;
        private readonly IConfiguration _config;

        public UsersService(IUserRepository usersRepository, IJWTService jwtService, ITokenBlacklistService tokenBlaclistService, IConnectionMultiplexer redis, IConfiguration config)
        {
            _usersRepository = usersRepository;
            _jwtService = jwtService;
            _tokenBlacklistService = tokenBlaclistService;
            _redis = redis;
            _config = config;
        }

        public async Task<(string?, string?)> VerifyLogin(string username, string password)
        {
            var loginUser = await _usersRepository.GetByUsernameAsync(username);

            if(loginUser != null)
            {
                if(loginUser.Status == false)
                {
                    return ("Tài khoản đã bị khóa", null);
                }

                var salt = loginUser.Salt;
                var storePassword = loginUser.Password;

                var hashPassword = HashingUtil.HashPassword(password, salt);

                if(hashPassword == storePassword)
                {
                    string? avatarBase64 = !string.IsNullOrEmpty(loginUser.AvatarUrl)
                        ? $"http://localhost:5270/avatar/{loginUser.AvatarUrl}"
                        : null;

                    string token = _jwtService.GenerateJwtToken(loginUser.Id, loginUser.Name, loginUser.Role.ToString());
                    loginUser.LastLogin = DateTime.UtcNow;
                    await _usersRepository.UpdateAsync(loginUser.Id, loginUser);
                    return (token, avatarBase64);
                }
                else
                {
                    return (null, null);
                }
            }
            else
            {
                return (null, null);
            }
        }

        public async Task<string> Register(string username, string fullname, string email, string password, string phoneNumber, DateTime dateOfBirth, int gender)
        {
            try
            {
                var salt = HashingUtil.GenerateSalt(16);
                var hashPassword = HashingUtil.HashPassword(password, salt);

                Users registerUser = new Users()
                {
                    Username = username,
                    Name = fullname,
                    Email = email,
                    Password = hashPassword,
                    PhoneNumber = phoneNumber,
                    DateOfBirth = dateOfBirth,
                    Salt = salt,
                    Gender = gender,
                    CreatedAt = DateTime.UtcNow,
                    Status = true,
                    LastLogin = null,
                    Role = "normal",
                    AvatarUrl = null,
                };

                await _usersRepository.CreateAsync(registerUser);
                return "Đăng ký thành công.";
            }
            catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
            {
                return "Email đã tồn tại.";
            }
            catch (Exception ex)
            {
                Console.WriteLine("Đã xảy ra lỗi " + ex.ToString());
                return "Đăng ký thất bại.";
            }
        }
        
        public async Task<bool> Logout(string token)
        {
            try
            {
                var handler = new JwtSecurityTokenHandler();
                var jwtToken = handler.ReadJwtToken(token);

                var id = jwtToken.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Sub)?.Value;

                if (string.IsNullOrEmpty(id))
                {
                    return false;
                }

                Users user = await _usersRepository.GetByIdAsync(id);
                if (user != null)
                {            

                    // Add token to blacklist
                    var expires = jwtToken.ValidTo;
                    await _tokenBlacklistService.AddToBlacklistAsync(id, expires);

                    // Clear any existing OTP and limit keys for this user
                    var db = _redis.GetDatabase();
                    await db.KeyDeleteAsync($"otp:{user.Email}");
                    await db.KeyDeleteAsync($"otp-limit:{user.Email}");

                    return true;
                }
                else
                {
                    Console.WriteLine($"Failed to log out: {id} not exist");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
                return false;
            }    
            return false;
        }

        public async Task<Users> GetProfileInfo(string userID)
        {
            try
            {
                return await _usersRepository.GetByIdAsync(userID);
            }
            catch (Exception ex) {
                return null;
            }
        }

        public async Task<string> UpdatePersonalData(string userID, string fullname, int gender, DateTime dateOfBirth, string avtUrl = null, string address = null, bool? isEmailVerified = null)
        {
            var user = await _usersRepository.GetByIdAsync(userID);
            if (user != null)
            {
                user.Name = fullname;
                user.Gender = gender;
                user.DateOfBirth = dateOfBirth;
                if (avtUrl != null)
                {
                    user.AvatarUrl = avtUrl;
                }
                if (address != null)
                {
                    user.Address = address;
                }
                if (isEmailVerified.HasValue)
                {
                    user.IsEmailVerified = isEmailVerified.Value;
                }
                await _usersRepository.UpdateAsync(userID, user);
                return "Success";
            }
            else
            {
                return null;
            }
        }

        public async Task<string> UpgradeTier(string userId, string tier)
        {
            var user = await _usersRepository.GetByIdAsync(userId);
            if (user != null)
            {
                user.Role = tier;

                if (user.ExpiredDate == null || user.ExpiredDate < DateTime.Now)
                {
                    user.ExpiredDate = DateTime.Now.AddDays(30);
                }
                else
                {
                    if (user.Role == tier)
                    {
                        user.ExpiredDate = user.ExpiredDate.AddDays(30);
                    }
                    else
                    {
                        user.ExpiredDate = DateTime.Now.AddDays(30);
                    }
                }

                await _usersRepository.UpdateAsync(userId, user);
                return "Success";
            }
            else
            {
                return null;
            }

        }

        public async Task<bool> SendOtpAsync(string email)
        {
            try
            {
                Console.WriteLine($"SendOtpAsync called for email: {email}");
                var db = _redis.GetDatabase();
                var user = await _usersRepository.GetByEmailAsync(email);

                if (user == null)
                {
                    Console.WriteLine($"User not found for email: {email}");
                    return false;
                }
                Console.WriteLine($"User found for email: {email}, user ID: {user.Id}");

                // Check if Redis is connected
                if (!_redis.IsConnected)
                {
                    Console.WriteLine("Redis is not connected. Attempting to reconnect...");
                    try
                    {
                        await _redis.GetDatabase().PingAsync();
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Failed to connect to Redis: {ex.Message}");
                        return false;
                    }
                }

                // Check spam limit with retry
                var retryCount = 0;
                var maxRetries = 3;
                while (retryCount < maxRetries)
                {
                    try
                    {
                        var limitKey = $"otp-limit:{email}";
                        var existingLimit = await db.StringGetAsync(limitKey);
                        
                        if (existingLimit != RedisValue.Null)
                        {
                            Console.WriteLine($"OTP limit exists for email: {email}, waiting for it to expire...");
                            // Force delete the limit key if it exists
                            await db.KeyDeleteAsync(limitKey);
                            Console.WriteLine($"Force deleted limit key for email: {email}");
                        }

                        // Gen OTP
                        var otp = new Random().Next(100000, 999999).ToString();
                        
                        // Set OTP and limit atomically
                        var otpKey = $"otp:{email}";
                        var transaction = db.CreateTransaction();
                        transaction.StringSetAsync(otpKey, otp, TimeSpan.FromMinutes(5));
                        transaction.StringSetAsync(limitKey, "1", TimeSpan.FromSeconds(60));
                        
                        if (await transaction.ExecuteAsync())
                        {
                            // Send mail
                            var smtpUser = _config["Gmail:Username"];
                            var smtpPass = _config["Gmail:AppPassword"]?.Replace(" ", ""); // Remove spaces from app password

                            using var client = new System.Net.Mail.SmtpClient("smtp.gmail.com")
                            {
                                Port = 587,
                                Credentials = new System.Net.NetworkCredential(smtpUser, smtpPass),
                                EnableSsl = true,
                            };

                            var mailMessage = new System.Net.Mail.MailMessage
                            {
                                From = new System.Net.Mail.MailAddress(smtpUser),
                                Subject = "Mã xác thực OTP",
                                Body = $"Mã OTP của bạn là: {otp}. Mã này có hiệu lực trong 5 phút.",
                                IsBodyHtml = false,
                            };
                            mailMessage.To.Add(email);

                            await client.SendMailAsync(mailMessage);
                            Console.WriteLine($"OTP sent successfully to {email}");
                            return true;
                        }
                        else
                        {
                            Console.WriteLine("Failed to set OTP in Redis transaction");
                            retryCount++;
                            await Task.Delay(100); // Wait before retry
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Error in SendOtpAsync retry {retryCount}: {ex.Message}");
                        retryCount++;
                        if (retryCount == maxRetries)
                            throw;
                        await Task.Delay(100); // Wait before retry
                    }
                }

                return false;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error in SendOtpAsync: {ex.Message}");
                return false;
            }
        }

        public async Task<bool> VerifyOnlyOtpAsync(string email, string otp)
        {
            var db = _redis.GetDatabase();
            var savedOtp = await db.StringGetAsync($"otp:{email}");
            return !savedOtp.IsNullOrEmpty && savedOtp == otp;
        }

        public async Task<bool> VerifyOtpAsync(string email, string otp, string newPassword)
        {
            try
            {
                if (!await VerifyOnlyOtpAsync(email, otp))
                {
                    return false;
                }

                var user = await _usersRepository.GetByEmailAsync(email);
                if (user == null)
                {
                    return false;
                }

                var newSalt = HashingUtil.GenerateSalt();
                var newHash = HashingUtil.HashPassword(newPassword, newSalt);
                user.Password = newHash;
                user.Salt = newSalt;

                await _usersRepository.UpdateAsync(user.Id, user);

                var db = _redis.GetDatabase();
                // Delete both OTP and limit keys
                await db.KeyDeleteAsync($"otp:{email}");
                await db.KeyDeleteAsync($"otp-limit:{email}");

                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"VerifyOtpAsync: An unexpected error occurred: {ex.ToString()}");
                return false;
            }
        }
        public async Task UpdateFollowCount(string id, int count)
        {
            var user = await _usersRepository.GetByIdAsync(id);
            if (user != null)
            {
                if(user.FollowCount == 0)
                {
                    return;
                }

                user.FollowCount = user.FollowCount + count;
                
                await _usersRepository.UpdateAsync(id, user);
            }
        }

        public async Task<bool> ChangePassword(string userId, string oldPassword, string newPassword)
        {
            var user = await _usersRepository.GetByIdAsync(userId);
            if (user == null)
                return false;
            var hashOld = HashingUtil.HashPassword(oldPassword, user.Salt);
            if (hashOld != user.Password)
                return false;
            var newSalt = HashingUtil.GenerateSalt();
            var newHash = HashingUtil.HashPassword(newPassword, newSalt);
            user.Password = newHash;
            user.Salt = newSalt;
            await _usersRepository.UpdateAsync(userId, user);
            return true;
        }
    }
}
