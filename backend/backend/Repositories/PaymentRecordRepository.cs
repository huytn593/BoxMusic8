using backend.Interfaces;
using backend.Models;
using MongoDB.Driver;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Repositories
{
    public class PaymentRecordRepository : IPaymentRecordRepository
    {
        private readonly IMongoCollection<PaymentRecord> _collection;

        public PaymentRecordRepository(IMongoDatabase database)
        {
            _collection = database.GetCollection<PaymentRecord>("paymentrecords");
        }

        public async Task AddAsync(PaymentRecord record)
        {
            await _collection.InsertOneAsync(record);
        }

        public async Task<IEnumerable<PaymentRecord>> GetByTimeRangeAsync(DateTime from, DateTime to)
        {
            var filter = Builders<PaymentRecord>.Filter.And(
                Builders<PaymentRecord>.Filter.Gte(r => r.PaymentTime, from),
                Builders<PaymentRecord>.Filter.Lte(r => r.PaymentTime, to)
            );

            return await _collection.Find(filter).ToListAsync();
        }

        public async Task<IEnumerable<PaymentRecord>> GetByTierAsync(string tier)
        {
            var filter = Builders<PaymentRecord>.Filter.Eq(r => r.Tier, tier);
            return await _collection.Find(filter).ToListAsync();
        }
    }
}
