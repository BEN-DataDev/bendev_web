export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      comments: {
        Row: {
          comment: string
          created_at: string
          id: number
          last_updated: string
          project_id: string
          user_id: string
        }
        Insert: {
          comment: string
          created_at?: string
          id?: never
          last_updated?: string
          project_id: string
          user_id?: string
        }
        Update: {
          comment?: string
          created_at?: string
          id?: never
          last_updated?: string
          project_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "comments_projectid_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_userid_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "userprofile"
            referencedColumns: ["id"]
          },
        ]
      }
      communities_projects: {
        Row: {
          community_id: string
          created_at: string
          id: string
          last_updated: string
          project_id: string
        }
        Insert: {
          community_id: string
          created_at?: string
          id?: string
          last_updated?: string
          project_id: string
        }
        Update: {
          community_id?: string
          created_at?: string
          id?: string
          last_updated?: string
          project_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "communities_projects_communityid_fkey"
            columns: ["community_id"]
            isOneToOne: false
            referencedRelation: "community"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "communities_projects_projectid_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
        ]
      }
      communities_users: {
        Row: {
          community_id: string
          created_at: string
          id: string
          last_updated: string
          user_id: string
        }
        Insert: {
          community_id: string
          created_at?: string
          id?: string
          last_updated?: string
          user_id: string
        }
        Update: {
          community_id?: string
          created_at?: string
          id?: string
          last_updated?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "communities_users_community_fk"
            columns: ["community_id"]
            isOneToOne: false
            referencedRelation: "community"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "communities_users_user_fk"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "userprofile"
            referencedColumns: ["id"]
          },
        ]
      }
      community: {
        Row: {
          communityinfo: Json | null
          contactinfo: Json | null
          created_at: string
          extent: unknown
          id: string
          last_updated: string
          name: string
        }
        Insert: {
          communityinfo?: Json | null
          contactinfo?: Json | null
          created_at?: string
          extent: unknown
          id?: string
          last_updated?: string
          name: string
        }
        Update: {
          communityinfo?: Json | null
          contactinfo?: Json | null
          created_at?: string
          extent?: unknown
          id?: string
          last_updated?: string
          name?: string
        }
        Relationships: []
      }
      community_user_roles: {
        Row: {
          community_user_id: string
          created_at: string
          id: string
          role: Database["public"]["Enums"]["user_community_role"]
        }
        Insert: {
          community_user_id: string
          created_at?: string
          id?: string
          role: Database["public"]["Enums"]["user_community_role"]
        }
        Update: {
          community_user_id?: string
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["user_community_role"]
        }
        Relationships: [
          {
            foreignKeyName: "community_user_roles_community_user_id_fkey"
            columns: ["community_user_id"]
            isOneToOne: false
            referencedRelation: "userprofile"
            referencedColumns: ["id"]
          },
        ]
      }
      project_user_roles: {
        Row: {
          created_at: string
          id: string
          project_user_id: string
          role: Database["public"]["Enums"]["user_project_role"]
        }
        Insert: {
          created_at?: string
          id?: string
          project_user_id: string
          role: Database["public"]["Enums"]["user_project_role"]
        }
        Update: {
          created_at?: string
          id?: string
          project_user_id?: string
          role?: Database["public"]["Enums"]["user_project_role"]
        }
        Relationships: [
          {
            foreignKeyName: "project_user_roles_project_user_id_fkey"
            columns: ["project_user_id"]
            isOneToOne: false
            referencedRelation: "userprofile"
            referencedColumns: ["id"]
          },
        ]
      }
      projects: {
        Row: {
          created_at: string
          id: string
          last_updated: string
          projectinfo: Json | null
          projectname: string
        }
        Insert: {
          created_at?: string
          id?: string
          last_updated?: string
          projectinfo?: Json | null
          projectname: string
        }
        Update: {
          created_at?: string
          id?: string
          last_updated?: string
          projectinfo?: Json | null
          projectname?: string
        }
        Relationships: []
      }
      projects_tables: {
        Row: {
          created_at: string
          id: string
          last_updated: string
          project_id: string
          schema_name: string
          table_name: string
          tableid: number
        }
        Insert: {
          created_at?: string
          id?: string
          last_updated?: string
          project_id: string
          schema_name?: string
          table_name: string
          tableid?: number
        }
        Update: {
          created_at?: string
          id?: string
          last_updated?: string
          project_id?: string
          schema_name?: string
          table_name?: string
          tableid?: number
        }
        Relationships: [
          {
            foreignKeyName: "projects_tables_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
        ]
      }
      projects_users: {
        Row: {
          created_at: string
          id: string
          last_updated: string
          project_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          last_updated?: string
          project_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          last_updated?: string
          project_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "projects_users_project_fk"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "projects_users_user_fk"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "userprofile"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string
          entity_id: string
          id: string
          last_updated: string
          role_name: Database["public"]["Enums"]["role_name"]
          role_type: Database["public"]["Enums"]["role_type"]
          user_id: string
        }
        Insert: {
          created_at?: string
          entity_id: string
          id?: string
          last_updated?: string
          role_name: Database["public"]["Enums"]["role_name"]
          role_type: Database["public"]["Enums"]["role_type"]
          user_id: string
        }
        Update: {
          created_at?: string
          entity_id?: string
          id?: string
          last_updated?: string
          role_name?: Database["public"]["Enums"]["role_name"]
          role_type?: Database["public"]["Enums"]["role_type"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_roles_user_fk"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "userprofile"
            referencedColumns: ["id"]
          },
        ]
      }
      userprofile: {
        Row: {
          avatar_path: string | null
          bio: string | null
          created_at: string
          firstname: string
          id: string
          last_updated: string
          lastname: string
          profile_picture: string | null
        }
        Insert: {
          avatar_path?: string | null
          bio?: string | null
          created_at?: string
          firstname: string
          id?: string
          last_updated?: string
          lastname: string
          profile_picture?: string | null
        }
        Update: {
          avatar_path?: string | null
          bio?: string | null
          created_at?: string
          firstname?: string
          id?: string
          last_updated?: string
          lastname?: string
          profile_picture?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      dev_download_crownlands: {
        Args: {
          use_get?: boolean
          delay_seconds?: number
        }
        Returns: Json
      }
      dev_process_downloads: {
        Args: {
          use_get?: boolean
          delay_seconds?: number
        }
        Returns: Json
      }
      get_user_roles: {
        Args: {
          user_id: string
        }
        Returns: Json
      }
      remove_user_from_community: {
        Args: {
          p_userid: string
          p_communityid: string
        }
        Returns: undefined
      }
      remove_user_from_project: {
        Args: {
          p_userid: string
          p_projectid: string
        }
        Returns: undefined
      }
      sync_existing_users: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
    }
    Enums: {
      role_name:
        | "owner"
        | "admin"
        | "editor"
        | "gis"
        | "viewer"
        | "moderator"
        | "member"
        | "system_admin"
        | "system_moderator"
      role_type: "project" | "community" | "global"
      system_role: "system_admin" | "system_moderator" | "system_user"
      user_community_role: "owner" | "admin" | "moderator" | "member"
      user_project_role: "owner" | "admin" | "editor" | "data_editor" | "viewer"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type PublicSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (PublicSchema["Tables"] & PublicSchema["Views"])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
        Database[PublicTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
      Database[PublicTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (PublicSchema["Tables"] &
        PublicSchema["Views"])
    ? (PublicSchema["Tables"] &
        PublicSchema["Views"])[PublicTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  PublicEnumNameOrOptions extends
    | keyof PublicSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : PublicEnumNameOrOptions extends keyof PublicSchema["Enums"]
    ? PublicSchema["Enums"][PublicEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof PublicSchema["CompositeTypes"]
    | { schema: keyof Database },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof Database }
  ? Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof PublicSchema["CompositeTypes"]
    ? PublicSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never
