using System.Security.Cryptography;
using System.Text;

namespace backend.Utils.Securities
{
    public class HashingUtil
    {
        //Hàm tạo muối
        public static string GenerateSalt(int size = 16)
        {
            var random = RandomNumberGenerator.Create();
            var bytes = new byte[size];
            random.GetBytes(bytes);
            return Convert.ToBase64String(bytes);
        }

        //Hàm băm SHA256
        public static string HashPassword(string password, string salt)
        {
            using var sha256 = SHA256.Create();
            var bytes = Encoding.UTF8.GetBytes(password + salt);
            var hashPass = sha256.ComputeHash(bytes);
            return Convert.ToBase64String(hashPass);
        }
    }
}
