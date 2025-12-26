using backend.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Interfaces
{
    public interface IUserRepository
    {
        Task<List<Users>> GetAllAsync();
        Task<Users> GetByIdAsync(string id);
        Task<Users> GetByUsernameAsync(string username);
        Task<Users> GetByEmailAsync(string email);
        Task CreateAsync(Users user);
        Task UpdateAsync(string id, Users user);
        Task DeleteAsync(string id);
        Task<List<Users>> SearchByUsernameOrNameAsync(string keyword);
        Task<List<Users>> GetManyByIdsAsync(IEnumerable<string> ids);
        Task<List<Users>> GetUsersByIdsAsync(IEnumerable<string> userIds);

    }
}
