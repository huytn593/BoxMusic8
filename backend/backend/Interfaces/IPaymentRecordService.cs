using backend.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Interfaces
{
    public interface IPaymentRecordService
    {
        Task AddPaymentAsync(PaymentRecord record);
        Task<IEnumerable<PaymentRecord>> GetByTimeRangeAsync(DateTime from, DateTime to);
        Task<IEnumerable<PaymentRecord>> GetByTierAsync(string tier);
    }
}
