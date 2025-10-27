import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RESTful API (JSONPlaceholder)',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PostPage(),
    );
  }
}

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final String baseUrl = "https://jsonplaceholder.typicode.com/posts";
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  /// GET - Lấy danh sách bài viết
  Future<void> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        setState(() {
          _posts = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              "Lỗi khi tải dữ liệu: ${response.statusCode} - ${response.reasonPhrase}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi kết nối: $e";
        _isLoading = false;
      });
    }
  }

  /// POST - Thêm bài viết mới
  Future<void> addPost() async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "title": "Bài viết mới từ HTTP",
        "body": "Đây là bài viết demo được thêm bằng POST.",
        "userId": 1
      }),
    );
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Thêm bài viết thành công")),
      );
      fetchPosts();
    }
  }

  /// PUT - Cập nhật toàn bộ bài viết
  Future<void> updatePost(int id) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "title": "Bài viết đã được cập nhật (PUT)",
        "body": "Nội dung bài viết đã được cập nhật toàn bộ.",
        "userId": 1
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✏️ Cập nhật (PUT) thành công")),
      );
      fetchPosts();
    }
  }

  /// PATCH - Cập nhật một phần bài viết
  Future<void> patchPost(int id) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"title": "Bài viết chỉnh sửa (PATCH)"}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🧩 Cập nhật (PATCH) thành công")),
      );
      fetchPosts();
    }
  }

  /// DELETE - Xoá bài viết
  Future<void> deletePost(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Xoá bài viết thành công")),
      );
      fetchPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RESTful API (HTTP + JSONPlaceholder)"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addPost,
        label: const Text("Thêm bài viết (POST)"),
        icon: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                  onRefresh: fetchPosts,
                  child: ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(post['id'].toString()),
                          ),
                          title: Text(
                            post['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            post['body'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'put') {
                                updatePost(post['id']);
                              } else if (value == 'patch') {
                                patchPost(post['id']);
                              } else if (value == 'delete') {
                                deletePost(post['id']);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                  value: 'put', child: Text("PUT - Update")),
                              const PopupMenuItem(
                                  value: 'patch', child: Text("PATCH - Edit")),
                              const PopupMenuItem(
                                  value: 'delete', child: Text("DELETE")),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
