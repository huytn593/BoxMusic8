using backend.Controllers;
using backend.DTOs;

namespace backend.Interfaces
{
    public interface IVnPayService
    {
        string CreatePaymentUrl(PaymentInformationModel model, HttpContext context);
        Task<PaymentResponseModel> PaymentExecute(IQueryCollection collections);
    }
}
