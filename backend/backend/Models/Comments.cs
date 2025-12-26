using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class Comments
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string Id { get; set; }

        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string TrackId { get; set; }

        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string UserId { get; set; }

        [Required(ErrorMessage = "Nội dung bình luận không được để trống.")]
        [BsonRequired]
        [BsonElement("content")]
        public string Content { get; set; }

        // ========== Thời gian ==========
        [BsonElement("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
