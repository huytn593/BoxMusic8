using backend.Interfaces;
using StackExchange.Redis;

namespace backend.Services
{
    public class RedisTokenBlacklistService : ITokenBlacklistService
    {
        private readonly IDatabase _db;

        public RedisTokenBlacklistService(IConnectionMultiplexer redis)
        {
            _db = redis.GetDatabase();
        }

        public async Task AddToBlacklistAsync(string jti, DateTime expires)
        {
            var expiry = expires - DateTime.UtcNow;
            if (expiry <= TimeSpan.Zero)
            {
                expiry = TimeSpan.FromMinutes(1); // Nếu token hết hạn rồi, lưu 1 phút để tránh lỗi
            }                

            await _db.StringSetAsync(GetRedisKey(jti), "blacklisted", expiry);
        }

        public async Task<bool> IsBlacklistedAsync(string jti)
        {
            return await _db.KeyExistsAsync(GetRedisKey(jti));
        }

        private string GetRedisKey(string jti)
        {
            return $"blacklist:{jti}";
        }
    }
}
