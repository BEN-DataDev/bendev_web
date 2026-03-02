export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
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
          public: boolean
        }
        Insert: {
          communityinfo?: Json | null
          contactinfo?: Json | null
          created_at?: string
          extent: unknown
          id?: string
          last_updated?: string
          name: string
          public?: boolean
        }
        Update: {
          communityinfo?: Json | null
          contactinfo?: Json | null
          created_at?: string
          extent?: unknown
          id?: string
          last_updated?: string
          name?: string
          public?: boolean
        }
        Relationships: []
      }
      health_status: {
        Row: {
          id: number
          last_check: string | null
        }
        Insert: {
          id?: number
          last_check?: string | null
        }
        Update: {
          id?: number
          last_check?: string | null
        }
        Relationships: []
      }
      keepalive: {
        Row: {
          id: number
          last_ping: string | null
        }
        Insert: {
          id?: number
          last_ping?: string | null
        }
        Update: {
          id?: number
          last_ping?: string | null
        }
        Relationships: []
      }
      project_attachments: {
        Row: {
          category: string | null
          created_at: string
          description: string | null
          file_name: string
          file_path: string
          file_size: number | null
          file_type: string
          id: string
          last_updated: string
          project_id: string
          uploaded_by: string | null
        }
        Insert: {
          category?: string | null
          created_at?: string
          description?: string | null
          file_name: string
          file_path: string
          file_size?: number | null
          file_type: string
          id?: string
          last_updated?: string
          project_id: string
          uploaded_by?: string | null
        }
        Update: {
          category?: string | null
          created_at?: string
          description?: string | null
          file_name?: string
          file_path?: string
          file_size?: number | null
          file_type?: string
          id?: string
          last_updated?: string
          project_id?: string
          uploaded_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "project_attachments_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "project_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "userprofile"
            referencedColumns: ["id"]
          },
        ]
      }
      project_layers: {
        Row: {
          created_at: string
          created_by: string | null
          description: string | null
          display_order: number
          editable: boolean
          geometry: unknown
          id: string
          last_updated: string
          layer_type: string
          name: string
          project_id: string
          source_url: string | null
          style: Json | null
          visible: boolean
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          display_order?: number
          editable?: boolean
          geometry?: unknown
          id?: string
          last_updated?: string
          layer_type: string
          name: string
          project_id: string
          source_url?: string | null
          style?: Json | null
          visible?: boolean
        }
        Update: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          display_order?: number
          editable?: boolean
          geometry?: unknown
          id?: string
          last_updated?: string
          layer_type?: string
          name?: string
          project_id?: string
          source_url?: string | null
          style?: Json | null
          visible?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "project_layers_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "userprofile"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "project_layers_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
        ]
      }
      projects: {
        Row: {
          bounds: unknown
          community_id: string | null
          created_at: string
          description: string | null
          end_date: string | null
          geometry: unknown
          id: string
          last_updated: string
          projectinfo: Json | null
          projectname: string
          public: boolean
          start_date: string | null
          status: string | null
        }
        Insert: {
          bounds?: unknown
          community_id?: string | null
          created_at?: string
          description?: string | null
          end_date?: string | null
          geometry?: unknown
          id?: string
          last_updated?: string
          projectinfo?: Json | null
          projectname: string
          public?: boolean
          start_date?: string | null
          status?: string | null
        }
        Update: {
          bounds?: unknown
          community_id?: string | null
          created_at?: string
          description?: string | null
          end_date?: string | null
          geometry?: unknown
          id?: string
          last_updated?: string
          projectinfo?: Json | null
          projectname?: string
          public?: boolean
          start_date?: string | null
          status?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "projects_community_id_fkey"
            columns: ["community_id"]
            isOneToOne: false
            referencedRelation: "community"
            referencedColumns: ["id"]
          },
        ]
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
          entity_id: string | null
          id: string
          last_updated: string
          role_name: Database["public"]["Enums"]["role_name"]
          role_type: Database["public"]["Enums"]["role_type"]
          user_id: string
        }
        Insert: {
          created_at?: string
          entity_id?: string | null
          id?: string
          last_updated?: string
          role_name: Database["public"]["Enums"]["role_name"]
          role_type: Database["public"]["Enums"]["role_type"]
          user_id: string
        }
        Update: {
          created_at?: string
          entity_id?: string | null
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
      create_project: {
        Args: {
          p_boundary_geojson?: string
          p_community_id?: string
          p_description?: string
          p_end_date?: string
          p_name: string
          p_public?: boolean
          p_start_date?: string
          p_status?: string
        }
        Returns: string
      }
      custom_access_token_hook: { Args: { event: Json }; Returns: Json }
      dev_download_crownlands: {
        Args: { delay_seconds?: number; use_get?: boolean }
        Returns: Json
      }
      dev_process_downloads: {
        Args: { delay_seconds?: number; use_get?: boolean }
        Returns: Json
      }
      get_communities_with_transformed_extent: {
        Args: never
        Returns: {
          communityinfo: Json
          contactinfo: Json
          created_at: string
          extent: unknown
          extent_bounds: number[]
          extent_center: number[]
          id: string
          last_updated: string
          name: string
          public: boolean
        }[]
      }
      get_community_with_transformed_extent: {
        Args: never
        Returns: {
          communityinfo: Json
          contactinfo: Json
          created_at: string
          extent: unknown
          id: string
          last_updated: string
          name: string
          public: boolean
        }[]
      }
      get_project: {
        Args: { p_id: string }
        Returns: {
          boundary: Json
          bounds: number[]
          community_id: string
          community_name: string
          created_at: string
          description: string
          end_date: string
          id: string
          last_updated: string
          projectname: string
          public: boolean
          start_date: string
          status: string
        }[]
      }
      get_user_roles: { Args: { user_id: string }; Returns: Json }
      health_check: { Args: never; Returns: Json }
      remove_user_from_community: {
        Args: { p_communityid: string; p_userid: string }
        Returns: undefined
      }
      remove_user_from_project: {
        Args: { p_projectid: string; p_userid: string }
        Returns: undefined
      }
      sync_existing_users: { Args: never; Returns: undefined }
      update_project: {
        Args: {
          p_boundary_geojson?: string
          p_community_id?: string
          p_description?: string
          p_end_date?: string
          p_id: string
          p_name: string
          p_public?: boolean
          p_start_date?: string
          p_status?: string
        }
        Returns: boolean
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
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      role_name: [
        "owner",
        "admin",
        "editor",
        "gis",
        "viewer",
        "moderator",
        "member",
        "system_admin",
        "system_moderator",
      ],
      role_type: ["project", "community", "global"],
    },
  },
} as const

