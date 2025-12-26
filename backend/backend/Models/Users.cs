﻿using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class Users
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string Id { get; set; }

        [Required(ErrorMessage = "Họ và tên không được để trống.")]
        [BsonRequired]
        [BsonElement("fullname")]
        public string Name { get; set; }

        [Required(ErrorMessage = "Tên đăng nhập không được để trống.")]
        [BsonRequired]
        [BsonElement("username")]
        public string Username { get; set; }

        [Required(ErrorMessage = "Email không được để trống.")]
        [EmailAddress(ErrorMessage = "Email không đúng định dạng.")]
        [BsonRequired]
        [BsonElement("email")]
        public string Email { get; set; }

        [Required(ErrorMessage = "Số điện thoại không được để trống.")]
        [Phone(ErrorMessage = "Số điện thoại không hợp lệ.")]
        [BsonRequired]
        [BsonElement("phone")]
        public string PhoneNumber { get; set; }

        [Required(ErrorMessage = "Mật khẩu không được để trống.")]
        [MinLength(8, ErrorMessage = "Mật khẩu phải có ít nhất 8 ký tự.")]
        [BsonRequired]
        [BsonElement("password")]
        public string Password { get; set; }

        [BsonElement("salt")]
        public string Salt { get; set; }

        [Required(ErrorMessage = "Ngày sinh không được để trống.")]
        [DataType(DataType.Date, ErrorMessage = "Ngày sinh không đúng định dạng.")]
        [BsonRequired]
        [BsonElement("dateofbirth")]
        public DateTime DateOfBirth { get; set; }

        [Range(0, 3, ErrorMessage = "Giới tính không hợp lệ.")]
        [BsonElement("gender")]
        public int Gender { get; set; }

        [BsonElement("status")]
        public bool Status { get; set; } = true;

        [BsonElement("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("last_login")]
        public DateTime? LastLogin { get; set; }

        [Url(ErrorMessage = "Đường dẫn ảnh đại diện không hợp lệ.")]
        [BsonElement("avatar_url")]
        public string? AvatarUrl { get; set; }

        [Range(1, 4, ErrorMessage = "Quyền tài khoản không hợp lệ.")]
        [BsonElement("role")]
        public string Role { get; set; } = "normal";

        [BsonElement("follow_count")]
        public int FollowCount { get; set; } = 0;

        [BsonElement("expired_date")]
        public DateTime ExpiredDate { get; set; }

        [BsonElement("address")]
        public string? Address { get; set; }

        [BsonElement("is_email_verified")]
        public bool IsEmailVerified { get; set; } = false;
    }
}

