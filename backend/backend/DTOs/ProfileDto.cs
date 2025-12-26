namespace backend.DTOs
{

    #region Lấy dữ liệu người dùng
    public class GetProfileDataResponse
    {
        public string fullname { get; set; }
        public string email { get; set; }
        public string phoneNumber { get; set; }
        public DateTime dateOfBirth { get; set; }
        public int gender { get; set; }
        public string avatarBase64 { get; set; }
        public DateTime expiredDate { get; set; }
        public string Role { get; set; }
        public string? address { get; set; }
        public bool isEmailVerified { get; set; }
        public int FollowCount { get; set; }
    }
    #endregion

    #region Cập nhật thông tin cá nhân
    public class PersonalRequest
    {
        public string FullName { get; set; }
        public int Gender { get; set; }
        public DateTime DateOfBirth { get; set; }
    }

    public class PersonalAvatarRequest
    {
        public string FullName { get; set; }
        public int Gender { get; set; }
        public DateTime DateOfBirth { get; set; }
        public IFormFile Avatar { get; set; }
    }
    public class UserTracksResponse
    {
        public string Role { get; set; }
        public List<TrackListItemDto> Tracks { get; set; }
    }
    #endregion

    public class PublicProfileDataDto
    {
        public string fullname { get; set; }
        public int gender { get; set; }
        public DateTime dateOfBirth { get; set; }
        public string Role { get; set; }
        public string avatarBase64 { get; set; }
        public int FollowCount { get; set; }
        public string? address { get; set; }
        public bool isEmailVerified { get; set; }
    }

    public class ChangePasswordRequest
    {
        public string OldPassword { get; set; }
        public string NewPassword { get; set; }
    }

    public class UpdateAddressRequest
    {
        public string Address { get; set; }
    }

    public class VerifyEmailOtpRequest
    {
        public string Otp { get; set; }
    }
}
