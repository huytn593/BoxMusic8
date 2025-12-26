using backend.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Interfaces
{
    public interface IFollowersRepository
    {
        Task FollowAsync(string followerId, string followingId);
        Task UnfollowAsync(string followerId, string followingId);
        Task<bool> IsFollowingAsync(string followerId, string followingId);
        Task<List<string>> GetFollowingListAsync(string followerId);
    }
} 