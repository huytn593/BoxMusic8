namespace backend.Interfaces
{
    public interface ITokenBlacklistService
    {
        Task AddToBlacklistAsync(string jti, DateTime expires);
        Task<bool> IsBlacklistedAsync(string jti);
    }
}
