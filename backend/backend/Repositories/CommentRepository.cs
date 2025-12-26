using backend.Interfaces;
using backend.Models;
using Microsoft.Extensions.Configuration;
using MongoDB.Driver;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Repositories
{
    public class CommentRepository : ICommentRepository
    {
        private readonly IMongoCollection<Comments> _comments;

        public CommentRepository(IMongoDatabase database)
        {
            _comments = database.GetCollection<Comments>("comments");
        }

        public async Task<List<Comments>> GetCommentsByTrackIdAsync(string trackId)
        {
            return await _comments
                .Find(c => c.TrackId == trackId)
                .SortByDescending(c => c.CreatedAt)
                .ToListAsync();
        }

        public async Task<Comments> GetByIdAsync(string id)
        {
            return await _comments.Find(c => c.Id == id).FirstOrDefaultAsync();
        }

        public async Task CreateAsync(Comments comment)
        {
            await _comments.InsertOneAsync(comment);
        }

        public async Task UpdateAsync(string id, Comments updatedComment)
        {
            await _comments.ReplaceOneAsync(c => c.Id == id, updatedComment);
        }

        public async Task DeleteAsync(string id)
        {
            await _comments.DeleteOneAsync(c => c.Id == id);
        }
    }
}
