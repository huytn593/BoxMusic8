using backend.Models;

namespace backend.Interfaces
{
    public interface IHistoryRepository
    {
        Task<IEnumerable<Histories>> GetAllAsync();
        Task<IEnumerable<Histories>> GetByUserIdAsync(string userId);
        Task AddOrUpdateAsync(Histories history);
        Task DeleteAsync(string userId, string trackId);
        Task DeleteAllAsync(string userId);
    }
}
