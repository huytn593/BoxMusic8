using System.ComponentModel.DataAnnotations;

namespace backend.DTOs
{
    #region Đăng nhập
    public class LoginRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class LoginResponse
    {
        public string Message { get; set; } = string.Empty;
        public string? Token { get; set; }
        public string? AvatarBase64 { get; set; }
    }
    #endregion

    # region Đăng ký
    public class RegisterRequest
    {
        public string FullName { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; }
        public string Email { get; set; }
        public string PhoneNumber { get; set; }
        public DateTime DateOfBirth { get; set; }
        public int Gender { get; set; }
    }

    public class RegisterResponse
    {
        public string Message { get; set; } = string.Empty;
    }
    #endregion

    #region Quên mật khẩu
    public class SendOtpRequest
    {
        public string Email { get; set; }
    }

    public class VerifyOtpRequest
    {
        [Required(ErrorMessage = "Email không được để trống")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "OTP không được để trống")]
        public string Otp { get; set; } = string.Empty;
    }

    public class ResetPasswordRequest
    {
        [Required(ErrorMessage = "Email không được để trống")]
        public string Email { get; set; }

        [Required(ErrorMessage = "OTP không được để trống")]
        public string Otp { get; set; }

        [Required(ErrorMessage = "Mật khẩu mới không được để trống")]
        public string NewPassword { get; set; }
    }
    #endregion
}
