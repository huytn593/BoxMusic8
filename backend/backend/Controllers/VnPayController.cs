using backend.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using backend.DTOs;

namespace backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class VnPayController : ControllerBase
    {
        private readonly IVnPayService _vnPayService;
        public VnPayController(IVnPayService vnPayService)
        {

            _vnPayService = vnPayService;
        }

        [Authorize]
        [HttpPost("create")]
        public async Task<IActionResult> CreatePaymentUrlVnpay(PaymentInformationModel model)
        {
            var url = _vnPayService.CreatePaymentUrl(model, HttpContext);

            return Ok(new PaymentUrlResponse { Url = url });
        }


        [HttpGet("return")]
        public async Task<IActionResult> PaymentCallbackVnpay()
        {
            var response = await _vnPayService.PaymentExecute(Request.Query);

            return Ok(response);
        }

        /// <summary>
        /// Endpoint để VNPay redirect về sau khi thanh toán
        /// Trả về HTML page với deep link để mở Flutter app
        /// </summary>
        [HttpGet("payment-result")]
        public async Task<IActionResult> PaymentResultRedirect()
        {
            // Xử lý payment callback
            var response = await _vnPayService.PaymentExecute(Request.Query);

            // Build query string từ query params để truyền vào app
            var queryString = string.Join("&", Request.Query.Select(q => $"{q.Key}={Uri.EscapeDataString(q.Value.ToString())}"));

            // Deep link scheme cho Flutter app
            var deepLink = $"musicresu://payment-result?{queryString}";
            
            // Fallback URL nếu app không mở được
            var fallbackUrl = "musicresu://payment-result";
            
            // Status message
            var statusMessage = response != null && response.Success ? "thành công" : "thất bại";

            // Trả về HTML page với JavaScript để redirect về app
            var html = $@"<!DOCTYPE html>
<html>
<head>
    <meta charset=""UTF-8"">
    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
    <title>Đang chuyển hướng...</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }}
        .container {{
            text-align: center;
            padding: 20px;
        }}
        .spinner {{
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-top: 4px solid white;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
        }}
        @keyframes spin {{
            0% {{ transform: rotate(0deg); }}
            100% {{ transform: rotate(360deg); }}
        }}
        button {{
            padding: 10px 20px;
            font-size: 16px;
            margin-top: 20px;
            cursor: pointer;
            background: white;
            color: #667eea;
            border: none;
            border-radius: 5px;
        }}
    </style>
</head>
<body>
    <div class=""container"">
        <h2>Đang chuyển hướng về ứng dụng...</h2>
        <div class=""spinner""></div>
        <p>Nếu ứng dụng không tự động mở, vui lòng quay lại ứng dụng thủ công.</p>
    </div>
    <script>
        // Thử mở app bằng deep link
        window.location.href = '{deepLink}';
        
        // Fallback: Nếu sau 2 giây app không mở, hiển thị thông báo
        setTimeout(function() {{
            document.body.innerHTML = `
                <div class=""container"">
                    <h2>Thanh toán {statusMessage}!</h2>
                    <p>Vui lòng quay lại ứng dụng để xem chi tiết.</p>
                    <button onclick=""window.location.href='{fallbackUrl}'"">
                        Mở ứng dụng
                    </button>
                </div>
            `;
        }}, 2000);
    </script>
</body>
</html>";

            return Content(html, "text/html; charset=utf-8");
        }
    }
}
