using backend.Interfaces;
using backend.Models;
using backend.Repositories;
using MongoDB.Driver;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Services
{
    public class PaymentRecordService : IPaymentRecordService
    {
        private readonly IPaymentRecordRepository _repo;

        public PaymentRecordService(IPaymentRecordRepository repo)
        {
            _repo = repo;
        }

        public async Task AddPaymentAsync(PaymentRecord record)
        {
            try
            {
                await _repo.AddAsync(record);
            }
            catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
            {
                return;
            }
        }

        public async Task<IEnumerable<PaymentRecord>> GetByTimeRangeAsync(DateTime from, DateTime to)
        {
            return await _repo.GetByTimeRangeAsync(from, to);
        }

        public async Task<IEnumerable<PaymentRecord>> GetByTierAsync(string tier)
        {
            return await _repo.GetByTierAsync(tier);
        }
    }
}
