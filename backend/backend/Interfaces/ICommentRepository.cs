using backend.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Interfaces
{
    public interface ICommentRepository
    {
        Task<List<Comments>> GetCommentsByTrackIdAsync(string trackId);
        Task<Comments> GetByIdAsync(string id);
        Task CreateAsync(Comments comment);
        Task UpdateAsync(string id, Comments updatedComment);
        Task DeleteAsync(string id);
    }
}
