using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class Playlist
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string Id { get; set; }

        [Required(ErrorMessage = "Tên playlist không được để trống.")]
        [BsonRequired]
        [BsonElement("name")]
        public string Name { get; set; }

        [BsonElement("user_id")]
        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string UserId { get; set; }

        [BsonElement("cover_image")]
        public string? Cover { get; set; }

        [BsonElement("description")]
        public string? Description { get; set; }

        [BsonElement("is_public")]
        public bool IsPublic { get; set; } = true;

        [BsonElement("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
} 