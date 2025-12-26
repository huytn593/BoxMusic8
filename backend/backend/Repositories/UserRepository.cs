using backend.Interfaces;
using backend.Models;
using Microsoft.Extensions.Options;
using MongoDB.Driver;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Repositories
{
    public class UserRepository : IUserRepository
    {
        private readonly IMongoCollection<Users> _usersCollection;

        public UserRepository(IMongoDatabase database)
        {
            _usersCollection = database.GetCollection<Users>("users");
        }

        public async Task<List<Users>> GetAllAsync()
        {
            return await _usersCollection.Find(_ =>  true).ToListAsync();
        }

        public async Task<Users> GetByIdAsync(string id)
        {
            return await _usersCollection.Find(u => u.Id == id).FirstOrDefaultAsync();
        }

        public async Task<Users> GetByUsernameAsync(string username)
        {
            return await _usersCollection.Find(u => u.Username == username).FirstOrDefaultAsync();
        }

        public async Task<Users> GetByEmailAsync(string email)
        {
            return await _usersCollection.Find(u => u.Email == email).FirstOrDefaultAsync();
        }

        public async Task CreateAsync(Users user)
        {
            await _usersCollection.InsertOneAsync(user);
        }

        public async Task UpdateAsync(string id, Users user)
        {
            await _usersCollection.ReplaceOneAsync(u => u.Id == id, user);
        }

        public async Task DeleteAsync(string id)
        {
            await _usersCollection.DeleteOneAsync(u => u.Id == id);
        }

        public async Task<List<Users>> SearchByUsernameOrNameAsync(string keyword)
        {
            var lowerKeyword = keyword.ToLower();
            var filter = Builders<Users>.Filter.Or(
                Builders<Users>.Filter.Regex(u => u.Username, new MongoDB.Bson.BsonRegularExpression(lowerKeyword, "i")),
                Builders<Users>.Filter.Regex(u => u.Name, new MongoDB.Bson.BsonRegularExpression(lowerKeyword, "i"))
            );
            return await _usersCollection.Find(filter).ToListAsync();
        }

        public async Task<List<Users>> GetManyByIdsAsync(IEnumerable<string> ids)
        {
            return await _usersCollection.Find(u => ids.Contains(u.Id)).ToListAsync();
        }

        public async Task<List<Users>> GetUsersByIdsAsync(IEnumerable<string> userIds)
        {
            return await _usersCollection
                .Find(u => userIds.Contains(u.Id))
                .ToListAsync();
        }
    }
}
