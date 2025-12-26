using backend.Interfaces;
using backend.Models;
using backend.Interfaces;
using backend.Models;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentRecordController : ControllerBase
    {
        private readonly IPaymentRecordService _paymentService;

        public PaymentRecordController(IPaymentRecordService paymentService)
        {
            _paymentService = paymentService;
        }

        // GET: api/payment-records/by-time?from=2025-06-01&to=2025-06-30
        [HttpGet("by-time")]
        public async Task<IActionResult> GetByTimeRange([FromQuery] DateTime from, [FromQuery] DateTime to)
        {
            if (from > to)
                return BadRequest("Thời gian bắt đầu phải nhỏ hơn thời gian kết thúc.");

            var records = await _paymentService.GetByTimeRangeAsync(from, to);
            return Ok(records);
        }

        // GET: api/payment-records/by-tier?tier=VIP
        [HttpGet("by-tier")]
        public async Task<IActionResult> GetByTier([FromQuery] string tier)
        {
            if (string.IsNullOrEmpty(tier))
                return BadRequest("Thiếu tham số tier.");

            var records = await _paymentService.GetByTierAsync(tier);
            return Ok(records);
        }
    }
}


