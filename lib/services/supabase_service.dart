import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/user_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  final supabase = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url:
          'https://gwipwoxbulgdfjgirtle.supabase.co', // Replace with your Supabase URL
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3aXB3b3hidWxnZGZqZ2lydGxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQwOTc0ODksImV4cCI6MjA1OTY3MzQ4OX0.a-r2-tqe8f9KHEkD_2yn2Uo3hYz2LdimjprI6nU_7gE', // Replace with your Supabase Anon Key
    );
  }

  // Sign Up
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        // Create user profile in the database
        await supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'created_at': DateTime.now().toIso8601String(),
        });

        return UserModel(
          id: response.user!.id,
          email: email,
          fullName: fullName,
        );
      }
      return null;
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error during sign up: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    }
  }

  // Sign In
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Get user profile from the database
        final userData = await supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error during sign in: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error during sign out: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  // Get Current User
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        final userData =
            await supabase.from('profiles').select().eq('id', user.id).single();

        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
