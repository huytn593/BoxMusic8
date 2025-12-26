using backend.Controllers;
using backend.Interfaces;
using backend.Models;
using backend.Services;
using backend.VnPay;
using backend.DTOs;

public class VnPayService : IVnPayService
{
    private readonly IConfiguration _configuration;
    private readonly IUsersService _usersService;
    private readonly IPaymentRecordService _paymentRecordService;
    public VnPayService(IConfiguration configuration, IUsersService usersService, IPaymentRecordService paymentRecordService)
    {
        _configuration = configuration;
        _usersService = usersService;
        _paymentRecordService = paymentRecordService;
    }

    public string CreatePaymentUrl(PaymentInformationModel model, HttpContext context)
    {
        var timeZoneById = TimeZoneInfo.FindSystemTimeZoneById(_configuration["TimeZoneId"]);
        var timeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timeZoneById);
        var tick = DateTime.Now.Ticks.ToString();
        var pay = new VnPayLibrary();
        var urlCallBack = _configuration["Vnpay:PaymentBackReturnUrl"];

        pay.AddRequestData("vnp_Version", _configuration["Vnpay:Version"]);
        pay.AddRequestData("vnp_Command", _configuration["Vnpay:Command"]);
        pay.AddRequestData("vnp_TmnCode", _configuration["Vnpay:TmnCode"]);
        pay.AddRequestData("vnp_Amount", ((int)model.Amount * 100).ToString());
        pay.AddRequestData("vnp_CreateDate", timeNow.ToString("yyyyMMddHHmmss"));
        pay.AddRequestData("vnp_CurrCode", _configuration["Vnpay:CurrCode"]);
        pay.AddRequestData("vnp_IpAddr", pay.GetIpAddress(context));
        pay.AddRequestData("vnp_Locale", _configuration["Vnpay:Locale"]);
        pay.AddRequestData("vnp_OrderInfo", $"{model.Name} {model.OrderDescription} {model.Amount}");
        pay.AddRequestData("vnp_OrderType", model.OrderType);
        pay.AddRequestData("vnp_ReturnUrl", urlCallBack);
        pay.AddRequestData("vnp_TxnRef", tick);

        var paymentUrl =
            pay.CreateRequestUrl(_configuration["Vnpay:BaseUrl"], _configuration["Vnpay:HashSecret"]);

        return paymentUrl;
    }

    public async Task<PaymentResponseModel> PaymentExecute(IQueryCollection collections)
    {
        var pay = new VnPayLibrary();
        var response = pay.GetFullResponseData(collections, _configuration["Vnpay:HashSecret"]);

        if (response != null && response.Success)
        {
            var result = await _usersService.UpgradeTier(response.UserId, response.Tier);

            var record = new PaymentRecord
            {
                UserId = response.UserId,
                OrderId = response.OrderId,
                Amount = response.Tier == "Premium" ? 199000 : 99000,
                PaymentTime = DateTime.UtcNow,
                Tier = response.Tier
            };

            await _paymentRecordService.AddPaymentAsync(record);
        }

        return response;
    }
}
